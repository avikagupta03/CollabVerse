import 'dart:math';
import '../models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMatcherService {
  /// Encode skills into vector representation for ML similarity
  List<double> _encodeSkills(List<String> skills) {
    const int dim = 32; // Increased dimension for better accuracy
    final vec = List<double>.filled(dim, 0.0);

    for (var skill in skills) {
      // Use hashCode with better distribution
      final code = skill.toLowerCase().hashCode.abs();
      final index = code % dim;
      vec[index] += 1.0;
    }

    // Normalize vector
    return _normalizeVector(vec);
  }

  /// Normalize vector to unit length
  List<double> _normalizeVector(List<double> vec) {
    double norm = sqrt(vec.fold(0, (sum, val) => sum + val * val));
    if (norm == 0) return vec;
    return vec.map((v) => v / norm).toList();
  }

  /// Cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot; // Already normalized
  }

  /// Calculate experience compatibility score
  double _experienceScore(int userExp, int requiredExp) {
    final diff = (userExp - requiredExp).abs();
    return 1.0 / (1.0 + diff); // Closer match = higher score
  }

  /// Calculate interest overlap score
  double _interestScore(
    List<String> userInterests,
    List<String> projectInterests,
  ) {
    if (userInterests.isEmpty || projectInterests.isEmpty) return 0.5;

    final overlap = userInterests
        .where(
          (interest) => projectInterests.any(
            (proj) => interest.toLowerCase().contains(proj.toLowerCase()),
          ),
        )
        .length;

    return overlap / max(userInterests.length, projectInterests.length);
  }

  /// ML-based team matching with weighted scoring
  List<Map<String, dynamic>> getSuggestedTeam({
    required List<String> requiredSkills,
    required int teamSize,
    required List<UserProfile> allUsers,
    required List<String> projectInterests,
    int requiredExperience = 1,
  }) {
    final reqVec = _encodeSkills(requiredSkills);
    final scored = <Map<String, dynamic>>[];

    for (final user in allUsers) {
      // Weights for different factors
      const double skillWeight = 0.5;
      const double experienceWeight = 0.2;
      const double interestWeight = 0.3;

      // Calculate scores
      final userVec = _encodeSkills(user.skills);
      final skillScore = _cosineSimilarity(reqVec, userVec);
      final expScore = _experienceScore(user.experience, requiredExperience);
      final interestScore = _interestScore(user.interests, projectInterests);

      // Combined weighted score
      final finalScore =
          (skillScore * skillWeight) +
          (expScore * experienceWeight) +
          (interestScore * interestWeight);

      scored.add({
        'user': user,
        'score': finalScore,
        'skillScore': skillScore,
        'expScore': expScore,
        'interestScore': interestScore,
      });
    }

    // Sort by score descending
    scored.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    final size = min(teamSize, scored.length);
    return scored.take(size).toList();
  }

  /// Advanced team composition analysis
  Map<String, dynamic> analyzeTeamComposition(List<UserProfile> team) {
    final allSkills = team.fold<Set<String>>(
      {},
      (prev, user) => prev..addAll(user.skills),
    );

    final avgExperience = team.isEmpty
        ? 0
        : team.fold(0, (sum, u) => sum + u.experience) / team.length;

    final skillCoverage = (allSkills.length / (team.length * 5).toInt()).clamp(
      0,
      1,
    );

    return {
      'team_size': team.length,
      'unique_skills': allSkills.length,
      'avg_experience': double.parse(avgExperience.toStringAsFixed(1)),
      'skill_coverage': double.parse(skillCoverage.toStringAsFixed(2)),
      'skills': allSkills.toList(),
      'diversity_score': _calculateDiversity(team),
    };
  }

  /// Calculate team diversity based on skills and experience
  double _calculateDiversity(List<UserProfile> team) {
    if (team.length <= 1) return 0;

    final skillVariances = <double>[];
    for (final user in team) {
      for (final otherUser in team) {
        if (user.uid != otherUser.uid) {
          final vec1 = _encodeSkills(user.skills);
          final vec2 = _encodeSkills(otherUser.skills);
          skillVariances.add(1 - _cosineSimilarity(vec1, vec2));
        }
      }
    }

    return skillVariances.isEmpty
        ? 0
        : skillVariances.reduce((a, b) => a + b) / skillVariances.length;
  }

  /// Main API for UI
  Future<List<Map<String, dynamic>>> generateSuggestions(Map request) async {
    try {
      // Load users from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final users = snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((user) => user.isAvailable)
          .toList();

      // Safe parsing
      final rawSize = request['team_size'];
      final teamSize = rawSize is int
          ? rawSize
          : rawSize is num
          ? rawSize.toInt()
          : int.tryParse(rawSize?.toString() ?? '') ?? 2;

      // Parse experience with proper null/type handling
      final rawExp = request['experience'];
      final requiredExp = rawExp is int
          ? rawExp
          : rawExp is num
          ? rawExp.toInt()
          : int.tryParse(rawExp?.toString() ?? '') ?? 1;

      // Generate suggestions
      final suggestions = getSuggestedTeam(
        requiredSkills: List<String>.from(request['required_skills'] ?? []),
        teamSize: teamSize,
        allUsers: users,
        projectInterests: List<String>.from(request['interests'] ?? []),
        requiredExperience: requiredExp,
      );

      return suggestions.map((item) {
        final user = item['user'] as UserProfile;
        final score = item['score'] as double;

        return {
          'user_id': user.uid,
          'name': user.name,
          'skills': user.skills,
          'interests': user.interests,
          'experience': user.experience,
          'score': double.parse(score.toStringAsFixed(3)),
          'skill_score': double.parse(
            (item['skillScore'] as double).toStringAsFixed(3),
          ),
          'exp_score': double.parse(
            (item['expScore'] as double).toStringAsFixed(3),
          ),
          'interest_score': double.parse(
            (item['interestScore'] as double).toStringAsFixed(3),
          ),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to generate suggestions: $e');
    }
  }

  /// Get team composition recommendations
  Future<Map<String, dynamic>> getTeamComposition(
    List<String> requiredSkills, {
    int teamSize = 5,
    int requiredExperience = 1,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final users = snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();

      final team = getSuggestedTeam(
        requiredSkills: requiredSkills,
        teamSize: teamSize,
        allUsers: users,
        projectInterests: [],
        requiredExperience: requiredExperience,
      );

      final teamUsers = team
          .map((item) => item['user'] as UserProfile)
          .toList();
      return analyzeTeamComposition(teamUsers);
    } catch (e) {
      throw Exception('Failed to get team composition: $e');
    }
  }
}
