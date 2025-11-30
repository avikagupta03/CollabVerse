import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'team_assistant_api.dart';

class TeamAssistantService {
  TeamAssistantService();

  final _firestore = FirebaseFirestore.instance;

  /// Generates a rich assistant reply by looking at the team profile, request
  /// skills, each member's skills, and (most importantly) the latest prompt.
  Future<String> generateAssistantReply({
    required String teamId,
    required String prompt,
  }) async {
    final teamDoc = await _firestore.collection('teams').doc(teamId).get();
    final teamData = teamDoc.data() ?? {};

    final description = (teamData['description'] ?? '').toString();
    final teamSkills = List<String>.from(teamData['skills'] ?? const []);
    final members = List<String>.from(teamData['members'] ?? const []);

    final memberProfiles = await Future.wait(members.map((uid) async {
      final snap = await _firestore.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      return {
        'uid': uid,
        'name': data['name'] ?? 'Teammate',
        'skills': List<String>.from(data['skills'] ?? const []),
        'bio': data['bio'] ?? '',
      };
    }));

    final llmPayload = {
      'prompt': prompt,
      'team': {
        'id': teamId,
        'description': description,
        'skills': teamSkills,
      },
      'members': memberProfiles,
    };

    final llmReply = await TeamAssistantApi.generateReply(llmPayload);
    if (llmReply != null) {
      return llmReply;
    }

    return _composeReply(
      prompt: prompt,
      description: description,
      teamSkills: teamSkills,
      memberProfiles: memberProfiles,
    );
  }

  String _composeReply({
    required String prompt,
    required String description,
    required List<String> teamSkills,
    required List<Map<String, dynamic>> memberProfiles,
  }) {
    final buffer = StringBuffer();

    final topic = description.isNotEmpty
        ? description
        : (teamSkills.isNotEmpty ? teamSkills.join(', ') : 'your current project');

    final intent = _analyzePrompt(prompt);
    final keywords = _extractKeyPhrases(prompt);
    buffer.writeln('**You asked:** $prompt');
    buffer.writeln('');

    if (intent.askCapabilities) {
      buffer.writeln('🤖 **What I can do for you**');
      buffer.writeln('- Brainstorm fresh features or positioning ideas for this project.');
      buffer.writeln('- Break down any idea into tasks, owners, and resources.');
      buffer.writeln('- Recommend stacks/APIs that match your prompt (AI, web, mobile, data).');
      buffer.writeln('- Review copy, pitches, or requirements and tighten the message.');
      buffer.writeln('- Keep every reply public so the full team stays aligned.');
      buffer.writeln('');
    }

    if (intent.askIdea) {
      buffer.writeln('💡 **Idea Options**');
      for (final idea in _proposeIdeas(topic, teamSkills, prompt, keywords)) {
        buffer.writeln('- $idea');
      }
      buffer.writeln('');
    }

    if (intent.askSteps) {
      buffer.writeln('📋 **Step-by-step plan**');
      final steps = _buildSteps(teamSkills, prompt, keywords);
      for (var i = 0; i < steps.length; i++) {
        buffer.writeln('${i + 1}. ${steps[i]}');
      }
      buffer.writeln('');
    }

    if (intent.askTools) {
      buffer.writeln('🧰 **Tools & resources to consider**');
      for (final tool in _proposeTools(teamSkills, prompt, keywords)) {
        buffer.writeln('- $tool');
      }
      buffer.writeln('');
    }

    if (intent.askTasks || intent.askTeamwork) {
      buffer.writeln('🤝 **Task split suggestion**');
      if (memberProfiles.isEmpty) {
        buffer.writeln('- Please fill in member profiles so I can tailor assignments.');
      } else {
        final focusAreas = _matchMembersToWork(memberProfiles, prompt, teamSkills);
        for (final entry in focusAreas) {
          buffer.writeln('- $entry');
        }
      }
      buffer.writeln('');
    }

    if (intent.askExamples) {
      buffer.writeln('📚 **Example next move**');
      buffer.writeln('- Draft a short paragraph describing how you imagine "${keywords.join(', ')}" working, then ask me to refine it.');
      buffer.writeln('- Ask "generate tasks for ${keywords.join(', ')}" or "rewrite this pitch" to dive deeper.');
      buffer.writeln('');
    }

    if (!intent.askedAnythingSpecific && !intent.askCapabilities) {
      // Provide a concise, generalized reply if intent detection failed
      buffer.writeln('Here is a quick pulse based on $topic and the signals "$keywords":');
      buffer.writeln('- Validate the problem with one interview focused on "$keywords".');
      buffer.writeln('- Ship the smallest usable version of "$keywords" in the next sprint.');
      buffer.writeln('- Measure success with a metric tied to "$keywords" (e.g., conversions, time saved).');
      buffer.writeln('');
    }

    buffer.writeln('I stay in the room, so feel free to ask follow-ups or turn me off once you have what you need.');

    return buffer.toString();
  }

  String _pickFocus(List<String> skills, String prompt) {
    if (prompt.toLowerCase().contains('ai') || skills.any((s) => s.toLowerCase().contains('ml'))) {
      return 'smart AI-powered assistant';
    }
    if (prompt.toLowerCase().contains('app') || skills.any((s) => s.toLowerCase().contains('flutter'))) {
      return 'cross-platform app';
    }
    if (prompt.toLowerCase().contains('web') || skills.any((s) => s.toLowerCase().contains('web'))) {
      return 'responsive web dashboard';
    }
    return skills.isNotEmpty ? skills.first : 'solid end-to-end demo';
  }

  List<String> _buildSteps(List<String> skills, String prompt, List<String> keywords) {
    final steps = <String>[
      'Define a one-line problem statement around "${keywords.join(' ')}" and agree on the success metric.',
      'Sketch the user journey specifically covering how "${keywords.join(' ')}" fits in.',
      'Build a thin slice that proves the experience end-to-end.',
      'Run a quick usability test or interview focusing on the scenario in your prompt.',
      'Summarize learnings and update backlog/tasks.'
    ];

    if (skills.any((s) => s.toLowerCase().contains('data'))) {
      steps.insert(3, 'Design the data model and decide how to capture key signals.');
    }
    if (prompt.toLowerCase().contains('hardware')) {
      steps.add('Plan procurement/testing schedule for hardware components.');
    }
    if (prompt.toLowerCase().contains('timeline')) {
      steps.add('Align on timeline with checkpoints (design freeze, MVP, testing, release).');
    }
    return steps;
  }

  List<String> _proposeTools(List<String> skills, String prompt, List<String> keywords) {
    final random = Random();
    final library = {
      'design': ['Figma for mockups', 'Notion for specs', 'Miro for story mapping'],
      'mobile': ['Flutter + Firebase', 'Supabase auth', 'Riverpod/Provider state'],
      'web': ['Next.js + Tailwind', 'Firebase Hosting', 'Cloud Functions'],
      'data': ['Firestore for realtime data', 'BigQuery or Supabase for analytics'],
      'ml': ['Vertex AI', 'Open-source LLMs (Llama, Mistral)', 'LangChain for orchestration'],
    };

    final picks = <String>{'Shared task board (Linear/Trello/Jira)'};
    for (final entry in library.entries) {
      if (skills.any((s) => s.toLowerCase().contains(entry.key))) {
        picks.add(entry.value[random.nextInt(entry.value.length)]);
      }
    }
    if (prompt.toLowerCase().contains('ai') || prompt.toLowerCase().contains('assistant')) {
      picks.add('Vertex AI / OpenAI for ideation + summarization');
    }
    if (picks.length < 3) {
      picks.addAll(['GitHub Projects for tracking', 'Firebase Crashlytics for QA']);
    }
    picks.add('Focus instrumentation on ${keywords.join(', ')} so you can prove impact.');
    return picks.toList();
  }

  IntentFlags _analyzePrompt(String prompt) {
    final lower = prompt.toLowerCase();
    bool containsAny(List<String> words) => words.any(lower.contains);
    final intent = IntentFlags();
    if (containsAny(['idea', 'think of', 'brainstorm', 'concept'])) intent.askIdea = true;
    if (containsAny(['step', 'plan', 'roadmap', 'how to'])) intent.askSteps = true;
    if (containsAny(['tool', 'tech stack', 'technology', 'library'])) intent.askTools = true;
    if (containsAny(['task', 'divide', 'assignment', 'role'])) intent.askTasks = true;
    if (containsAny(['teamwork', 'collaborate', 'members'])) intent.askTeamwork = true;
    if (containsAny(['what can you do', 'can you do', 'help with', 'capabilities', 'who are you'])) {
      intent.askCapabilities = true;
    }
    if (containsAny(['example', 'sample', 'demo'])) {
      intent.askExamples = true;
    }
    intent.askedAnythingSpecific =
        intent.askIdea || intent.askSteps || intent.askTools || intent.askTasks || intent.askTeamwork || intent.askExamples;
    return intent;
  }

  List<String> _proposeIdeas(String topic, List<String> skills, String prompt, List<String> keywords) {
    final focus = _pickFocus(skills, prompt);
    final extras = <String>[
      'Deliver a ${focus.toLowerCase()} that solves "$prompt" in a single screen.',
      'Prototype a walkthrough showing before/after impact for "$topic".',
      'Create a data-backed insight panel leveraging your ${skills.isEmpty ? 'team strengths' : skills.join(', ')}.',
      'Focus on "${keywords.join(', ')}" as the signature experience and keep everything else optional.',
    ];
    if (prompt.toLowerCase().contains('game')) {
      extras.add('Build a gamified challenge with rewards tied to learning outcomes.');
    }
    if (prompt.toLowerCase().contains('education')) {
      extras.add('Offer adaptive learning paths using quizzes + analytics.');
    }
    if (keywords.isEmpty) {
      extras.add('Interview one target user and map the biggest pain before building.');
    }
    extras.shuffle();
    return extras;
  }

  List<String> _matchMembersToWork(
    List<Map<String, dynamic>> members,
    String prompt,
    List<String> teamSkills,
  ) {
    final assignments = <String>[];
    for (final member in members) {
      final name = member['name'] as String;
      final skills = (member['skills'] as List<String>);
      final bio = (member['bio'] as String?) ?? '';
      final specialty = skills.isNotEmpty
          ? skills.first
          : (bio.isNotEmpty ? bio.split(' ').take(3).join(' ') : 'generalist tasks');
      assignments.add('**$name** → lead $specialty work, unblock teammates on anything related to "$prompt".');
    }

    if (assignments.isEmpty && teamSkills.isNotEmpty) {
      assignments.add('Assign owners for ${teamSkills.join(', ')} to keep momentum.');
    }
    return assignments;
  }

  List<String> _extractKeyPhrases(String prompt) {
    final sanitized = prompt
        .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .toList();

    const stopWords = {
      'about', 'also', 'just', 'that', 'this', 'with', 'from', 'have', 'will',
      'need', 'your', 'what', 'when', 'where', 'which', 'them', 'they', 'team'
    };

    final keywords = <String>{};
    for (final word in sanitized) {
      if (!stopWords.contains(word)) {
        keywords.add(word);
      }
      if (keywords.length >= 4) break;
    }

    return keywords.isEmpty ? ['project focus'] : keywords.toList();
  }
}

class IntentFlags {
  bool askIdea = false;
  bool askSteps = false;
  bool askTools = false;
  bool askTasks = false;
  bool askTeamwork = false;
  bool askCapabilities = false;
  bool askExamples = false;
  bool askedAnythingSpecific = false;
}
