import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

/// Match type classification
enum SkillMatchType { strong, weak, none }

/// Individual match result
class SkillMatch {
  final String requiredSkill;
  final String bestMatchingUserSkill;
  final double similarityScore;
  final SkillMatchType matchType;

  SkillMatch({
    required this.requiredSkill,
    required this.bestMatchingUserSkill,
    required this.similarityScore,
    required this.matchType,
  });

  Map<String, dynamic> toJson() => {
    'required_skill': requiredSkill,
    'best_matching_user_skill': bestMatchingUserSkill,
    'similarity_score': double.parse(similarityScore.toStringAsFixed(4)),
    'match_type': matchType.name,
  };
}

/// Overall matching result
class SkillMatchingResult {
  final List<SkillMatch> matches;
  final double overallScore;
  final int strongMatches;
  final int weakMatches;
  final int noMatches;

  SkillMatchingResult({
    required this.matches,
    required this.overallScore,
    required this.strongMatches,
    required this.weakMatches,
    required this.noMatches,
  });

  Map<String, dynamic> toJson() => {
    'matches': matches.map((m) => m.toJson()).toList(),
    'overall_score': double.parse(overallScore.toStringAsFixed(4)),
    'summary': {
      'strong_matches': strongMatches,
      'weak_matches': weakMatches,
      'no_matches': noMatches,
      'total_required': matches.length,
    },
  };

  String toJsonString() => jsonEncode(toJson());
}

/// Semantic skill matcher using Hugging Face sentence-transformers
/// Uses "sentence-transformers/all-MiniLM-L6-v2" model for embeddings
class SemanticSkillMatcher {
  static const String _huggingFaceModel =
      'sentence-transformers/all-MiniLM-L6-v2';
  static const String _huggingFaceApi =
      'https://api-inference.huggingface.co/models/$_huggingFaceModel';

  // Cache for embeddings to reduce API calls
  static final Map<String, List<double>> _embeddingCache = {};

  /// Get embeddings from Hugging Face API
  /// Caches results to reduce API calls
  static Future<List<double>> _getEmbedding(
    String text,
    String huggingFaceToken,
  ) async {
    // Check cache first
    if (_embeddingCache.containsKey(text)) {
      return _embeddingCache[text]!;
    }

    try {
      final response = await http
          .post(
            Uri.parse(_huggingFaceApi),
            headers: {
              'Authorization': 'Bearer $huggingFaceToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'inputs': text}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Embedding request timeout'),
          );

      if (response.statusCode == 200) {
        final List<dynamic> embedding = jsonDecode(response.body)[0];
        final List<double> doubleEmbedding = embedding
            .map((e) => (e as num).toDouble())
            .toList();

        // Cache the result
        _embeddingCache[text] = doubleEmbedding;
        return doubleEmbedding;
      } else if (response.statusCode == 503) {
        throw Exception('Hugging Face API model is loading. Please retry.');
      } else {
        throw Exception(
          'Failed to get embedding: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Embedding API error: $e');
    }
  }

  /// Calculate cosine similarity between two embeddings
  static double _cosineSimilarity(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) {
      throw Exception('Embedding dimensions must match');
    }

    // Dot product
    double dotProduct = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
    }

    // Magnitudes
    double magnitude1 = sqrt(
      embedding1.fold(0.0, (sum, val) => sum + val * val),
    );
    double magnitude2 = sqrt(
      embedding2.fold(0.0, (sum, val) => sum + val * val),
    );

    if (magnitude1 == 0 || magnitude2 == 0) {
      return 0.0;
    }

    return dotProduct / (magnitude1 * magnitude2);
  }

  /// Classify match based on similarity score
  static SkillMatchType _classifyMatch(double score) {
    if (score >= 0.8) {
      return SkillMatchType.strong;
    } else if (score >= 0.1) {
      return SkillMatchType.weak;
    } else {
      return SkillMatchType.none;
    }
  }

  /// Perform semantic skill matching
  /// Returns JSON with detailed match results
  static Future<String> matchSkillsJSON({
    required List<String> userSkills,
    required List<String> requiredSkills,
    required String huggingFaceToken,
  }) async {
    try {
      final result = await matchSkills(
        userSkills: userSkills,
        requiredSkills: requiredSkills,
        huggingFaceToken: huggingFaceToken,
      );
      return result.toJsonString();
    } catch (e) {
      return jsonEncode({
        'error': e.toString(),
        'matches': [],
        'overall_score': 0.0,
      });
    }
  }

  /// Perform semantic skill matching
  /// Returns SkillMatchingResult with detailed information
  static Future<SkillMatchingResult> matchSkills({
    required List<String> userSkills,
    required List<String> requiredSkills,
    required String huggingFaceToken,
  }) async {
    if (requiredSkills.isEmpty) {
      return SkillMatchingResult(
        matches: [],
        overallScore: 100.0,
        strongMatches: 0,
        weakMatches: 0,
        noMatches: 0,
      );
    }

    if (userSkills.isEmpty) {
      final matches = requiredSkills.map((skill) {
        return SkillMatch(
          requiredSkill: skill,
          bestMatchingUserSkill: 'N/A',
          similarityScore: 0.0,
          matchType: SkillMatchType.none,
        );
      }).toList();

      return SkillMatchingResult(
        matches: matches,
        overallScore: 0.0,
        strongMatches: 0,
        weakMatches: 0,
        noMatches: matches.length,
      );
    }

    // Get embeddings for all skills
    print('Fetching embeddings for ${userSkills.length} user skills...');
    final userEmbeddings = <String, List<double>>{};
    for (final skill in userSkills) {
      userEmbeddings[skill] = await _getEmbedding(skill, huggingFaceToken);
    }

    print(
      'Fetching embeddings for ${requiredSkills.length} required skills...',
    );
    final requiredEmbeddings = <String, List<double>>{};
    for (final skill in requiredSkills) {
      requiredEmbeddings[skill] = await _getEmbedding(skill, huggingFaceToken);
    }

    // Calculate matches for each required skill
    print('Calculating similarity scores...');
    final List<SkillMatch> matches = [];
    int strongCount = 0;
    int weakCount = 0;
    int noneCount = 0;
    double totalScore = 0.0;

    for (final requiredSkill in requiredSkills) {
      final requiredEmbedding = requiredEmbeddings[requiredSkill]!;
      double bestScore = -1.0;
      String bestUserSkill = 'N/A';

      // Find best matching user skill
      for (final userSkill in userSkills) {
        final userEmbedding = userEmbeddings[userSkill]!;
        final similarity = _cosineSimilarity(userEmbedding, requiredEmbedding);

        if (similarity > bestScore) {
          bestScore = similarity;
          bestUserSkill = userSkill;
        }
      }

      // Classify match type
      final matchType = _classifyMatch(bestScore);
      matches.add(
        SkillMatch(
          requiredSkill: requiredSkill,
          bestMatchingUserSkill: bestUserSkill,
          similarityScore: bestScore,
          matchType: matchType,
        ),
      );

      // Count match types
      if (matchType == SkillMatchType.strong) {
        strongCount++;
        totalScore += bestScore;
      } else if (matchType == SkillMatchType.weak) {
        weakCount++;
        totalScore += bestScore * 0.5; // Weight weak matches less
      } else {
        noneCount++;
      }
    }

    // Calculate overall score
    final overallScore = requiredSkills.isNotEmpty
        ? (totalScore / requiredSkills.length) * 100
        : 0.0;

    // Sort: strong (desc), weak (desc), none (0.0)
    matches.sort((a, b) {
      // Strong matches first
      if (a.matchType == SkillMatchType.strong &&
          b.matchType != SkillMatchType.strong) {
        return -1;
      }
      if (a.matchType != SkillMatchType.strong &&
          b.matchType == SkillMatchType.strong) {
        return 1;
      }

      // Weak matches second
      if (a.matchType == SkillMatchType.weak &&
          b.matchType == SkillMatchType.none) {
        return -1;
      }
      if (a.matchType == SkillMatchType.none &&
          b.matchType == SkillMatchType.weak) {
        return 1;
      }

      // Within same type, sort by score descending
      if (a.matchType == b.matchType) {
        return b.similarityScore.compareTo(a.similarityScore);
      }

      return 0;
    });

    return SkillMatchingResult(
      matches: matches,
      overallScore: overallScore.clamp(0, 100),
      strongMatches: strongCount,
      weakMatches: weakCount,
      noMatches: noneCount,
    );
  }

  /// Clear embedding cache (useful for memory management)
  static void clearCache() {
    _embeddingCache.clear();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cached_embeddings': _embeddingCache.length,
      'cache_memory_estimate_kb':
          (_embeddingCache.length * 384 * 8) ~/
          1024, // Estimate for all-MiniLM-L6-v2
    };
  }
}
