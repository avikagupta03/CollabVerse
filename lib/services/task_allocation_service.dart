import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/task_allocation_model.dart';
import '../models/user_profile.dart';

class TaskAllocationService {
  final _fs = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Smart allocation - analyzes requirements, generates tasks, assigns to team members
  Future<TaskAllocation> smartAllocateTasks({
    required String projectRequirement,
    required List<UserProfile> teamMembers,
    required String teamId,
  }) async {
    // Generate tasks from requirements
    final tasks = _generateTasksFromRequirement(projectRequirement);

    // Allocate tasks to team members based on skills
    final allocations = _allocateTasksToMembers(tasks, teamMembers);

    // Calculate confidence score
    final confidence = _calculateConfidenceScore(tasks, allocations);

    // Create allocation object
    final allocation = TaskAllocation(
      projectRequirement: projectRequirement,
      generatedTasks: tasks,
      allocations: allocations,
      createdAt: DateTime.now(),
      confidenceScore: confidence,
    );

    // Save to Firestore
    await _saveAllocation(teamId, allocation);

    return allocation;
  }

  /// Generate tasks by analyzing project requirements
  List<Task> _generateTasksFromRequirement(String requirement) {
    final tasks = <Task>[];
    final lower = requirement.toLowerCase();

    // UI/Frontend tasks
    if (lower.contains(RegExp(r'(ui|design|interface|frontend|screen)'))) {
      tasks.add(
        Task(
          id: _uuid.v4(),
          title: 'UI/Frontend Development',
          description: 'Design and build user interface components',
          category: 'UI',
          requiredSkills: ['Flutter', 'Dart', 'UI Design', 'Material Design'],
          priority: 'High',
          estimatedHours: 40,
          assignedTo: '',
          assignedToName: 'Unassigned',
          createdAt: DateTime.now(),
        ),
      );
    }

    // Backend/API tasks
    if (lower.contains(RegExp(r'(backend|api|server|database|firestore)'))) {
      tasks.add(
        Task(
          id: _uuid.v4(),
          title: 'Backend & API Development',
          description: 'Build backend services and integrate APIs',
          category: 'Backend',
          requiredSkills: [
            'Backend Development',
            'Firebase',
            'Firestore',
            'REST API',
          ],
          priority: 'High',
          estimatedHours: 50,
          assignedTo: '',
          assignedToName: 'Unassigned',
          createdAt: DateTime.now(),
        ),
      );
    }

    // ML/AI tasks
    if (lower.contains(
      RegExp(r'(machine learning|ai|model|prediction|neural)'),
    )) {
      tasks.add(
        Task(
          id: _uuid.v4(),
          title: 'ML/AI Model Development',
          description: 'Build and train machine learning models',
          category: 'ML',
          requiredSkills: [
            'Machine Learning',
            'Python',
            'TensorFlow',
            'Data Science',
          ],
          priority: 'High',
          estimatedHours: 60,
          assignedTo: '',
          assignedToName: 'Unassigned',
          createdAt: DateTime.now(),
        ),
      );
    }

    // Testing/QA tasks
    if (lower.contains(RegExp(r'(test|qa|quality|validation|debug)'))) {
      tasks.add(
        Task(
          id: _uuid.v4(),
          title: 'Testing & QA',
          description: 'Comprehensive testing and quality assurance',
          category: 'Testing',
          requiredSkills: ['Testing', 'QA', 'Debugging', 'Test Automation'],
          priority: 'Medium',
          estimatedHours: 30,
          assignedTo: '',
          assignedToName: 'Unassigned',
          createdAt: DateTime.now(),
        ),
      );
    }

    // DevOps/Deployment tasks
    if (lower.contains(
      RegExp(r'(deploy|devops|ci/cd|docker|infrastructure)'),
    )) {
      tasks.add(
        Task(
          id: _uuid.v4(),
          title: 'DevOps & Deployment',
          description: 'Setup CI/CD and deployment infrastructure',
          category: 'DevOps',
          requiredSkills: ['DevOps', 'Docker', 'CI/CD', 'Infrastructure'],
          priority: 'Medium',
          estimatedHours: 25,
          assignedTo: '',
          assignedToName: 'Unassigned',
          createdAt: DateTime.now(),
        ),
      );
    }

    // Default tasks if nothing matched
    if (tasks.isEmpty) {
      tasks.addAll([
        Task(
          id: _uuid.v4(),
          title: 'Frontend Development',
          description: 'Build user-facing features',
          category: 'UI',
          requiredSkills: ['Flutter', 'Dart'],
          priority: 'High',
          estimatedHours: 40,
          assignedTo: '',
          assignedToName: 'Unassigned',
          createdAt: DateTime.now(),
        ),
        Task(
          id: _uuid.v4(),
          title: 'Backend Development',
          description: 'Build backend services',
          category: 'Backend',
          requiredSkills: ['Backend', 'Firebase'],
          priority: 'High',
          estimatedHours: 40,
          assignedTo: '',
          assignedToName: 'Unassigned',
          createdAt: DateTime.now(),
        ),
      ]);
    }

    return tasks;
  }

  /// Allocate tasks to team members based on skills match
  List<AllocationResult> _allocateTasksToMembers(
    List<Task> tasks,
    List<UserProfile> members,
  ) {
    final allocations = <AllocationResult>[];

    // Allocate tasks to members with matching skills
    for (final member in members) {
      final memberTasks = <Task>[];
      double totalMatch = 0;
      int matchCount = 0;

      for (final task in tasks) {
        final skillMatch = _calculateSkillMatch(
          task.requiredSkills,
          member.skills,
        );

        // Allocate if skill match > 50%
        if (skillMatch > 50) {
          memberTasks.add(
            task.copyWith(
              assignedTo: member.uid,
              assignedToName: member.name,
              status: 'Assigned',
            ),
          );
          totalMatch += skillMatch;
          matchCount++;
        }
      }

      if (memberTasks.isNotEmpty) {
        final avgMatch = totalMatch / matchCount;
        allocations.add(
          AllocationResult(
            memberId: member.uid,
            memberName: member.name,
            tasks: memberTasks,
            matchPercentage: avgMatch,
            availableSkills: member.skills,
            matchReason:
                '$member.name: ${memberTasks.length} tasks, $avgMatch% skill match',
          ),
        );
      }
    }

    return allocations;
  }

  /// Calculate skill match percentage between task requirements and member skills
  double _calculateSkillMatch(
    List<String> requiredSkills,
    List<String> memberSkills,
  ) {
    if (requiredSkills.isEmpty) return 100;

    final memberSkillsLower = memberSkills.map((s) => s.toLowerCase()).toList();
    int matches = 0;

    for (final skill in requiredSkills) {
      if (memberSkillsLower.contains(skill.toLowerCase())) {
        matches++;
      }
    }

    return (matches / requiredSkills.length) * 100;
  }

  /// Calculate overall confidence score for allocation
  double _calculateConfidenceScore(
    List<Task> tasks,
    List<AllocationResult> allocations,
  ) {
    if (tasks.isEmpty || allocations.isEmpty) return 50;

    // Average of all member match percentages
    final avgMatch = allocations.isNotEmpty
        ? allocations.fold<double>(0, (sum, a) => sum + a.matchPercentage) /
              allocations.length
        : 0;

    // Workload balance score
    final balance = _getWorkloadBalanceScore(allocations);

    // Combined score
    return (avgMatch + (balance * 100)) / 2;
  }

  /// Calculate workload balance (higher = better distribution)
  double _getWorkloadBalanceScore(List<AllocationResult> allocations) {
    if (allocations.isEmpty) return 0;

    final hours = allocations.map((a) => a.getTotalHours()).toList();
    final minHours = hours.reduce((a, b) => a < b ? a : b).toDouble();
    final maxHours = hours.reduce((a, b) => a > b ? a : b).toDouble();

    if (maxHours == 0) return 1;
    return 1 - ((maxHours - minHours) / maxHours) * 0.5;
  }

  /// Save allocation to Firestore
  Future<void> _saveAllocation(String teamId, TaskAllocation allocation) async {
    final allocationId = _uuid.v4();

    // Save allocation metadata
    await _fs
        .collection('teams')
        .doc(teamId)
        .collection('allocations')
        .doc(allocationId)
        .set({
          'id': allocationId,
          'project_requirement': allocation.projectRequirement,
          'total_tasks': allocation.generatedTasks.length,
          'confidence_score': allocation.confidenceScore,
          'created_at': FieldValue.serverTimestamp(),
        });

    // Save individual tasks
    for (final task in allocation.generatedTasks) {
      await _fs
          .collection('teams')
          .doc(teamId)
          .collection('tasks')
          .doc(task.id)
          .set({...task.toMap(), 'allocation_id': allocationId});
    }
  }

  /// Get allocation history for a team
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllocations(String teamId) {
    return _fs
        .collection('teams')
        .doc(teamId)
        .collection('allocations')
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}
