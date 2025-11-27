class UserModel {
  final String uid;
  final String name;
  final List<String> skills;
  final List<String> interests;
  final String? photo;


  UserModel({required this.uid, required this.name, required this.skills, required this.interests, this.photo});


  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      interests: List<String>.from(data['interests'] ?? []),
      photo: data['profile_photo'],
    );
  }
}