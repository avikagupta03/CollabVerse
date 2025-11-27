class TeamRequestModel {
  final String id;
  final List<String> requiredSkills;
  final int teamSize;
  final String description;
  final List<dynamic> suggestions;


  TeamRequestModel({required this.id, required this.requiredSkills, required this.teamSize, required this.description, required this.suggestions});


  factory TeamRequestModel.fromMap(String id, Map<String, dynamic> data) {
    return TeamRequestModel(
      id: id,
      requiredSkills: List<String>.from(data['required_skills'] ?? []),
      teamSize: data['team_size'] ?? 3,
      description: data['description'] ?? '',
      suggestions: data['suggested_teams'] ?? [],
    );
  }
}