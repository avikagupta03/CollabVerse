/// Utility class for calculating skill similarity between users and team requests
class SkillSimilarityCalculator {
  /// Calculate similarity score between user's skills and required skills
  /// Returns a score from 0 to 100
  static double calculateSimilarity(
    List<String> userSkills,
    List<String> requiredSkills,
  ) {
    if (requiredSkills.isEmpty) return 100;
    if (userSkills.isEmpty) return 0;

    // Normalize skills to lowercase for comparison
    final userSkillsLower = userSkills.map((s) => s.toLowerCase()).toSet();
    final requiredSkillsLower = requiredSkills
        .map((s) => s.toLowerCase())
        .toSet();

    // Count exact matches
    final exactMatches = userSkillsLower
        .intersection(requiredSkillsLower)
        .length;

    // Calculate percentage of required skills user has
    final matchPercentage = (exactMatches / requiredSkillsLower.length) * 100;

    return matchPercentage.clamp(0, 100);
  }

  /// Get matching skills between user and required skills
  static List<String> getMatchingSkills(
    List<String> userSkills,
    List<String> requiredSkills,
  ) {
    final userSkillsLower = userSkills.map((s) => s.toLowerCase()).toSet();
    return requiredSkills
        .where((skill) => userSkillsLower.contains(skill.toLowerCase()))
        .toList();
  }
}
