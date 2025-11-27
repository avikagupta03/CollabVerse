class TeamModel {
  final String id;
  final String name;
  final String projectName;
  final List<String> members;


  TeamModel({required this.id, required this.name, required this.projectName, required this.members});


  factory TeamModel.fromMap(String id, Map<String, dynamic> data) {
    return TeamModel(
      id: id,
      name: data['name'] ?? '',
      projectName: data['project_name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }
}