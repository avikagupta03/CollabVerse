import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequestModel {
  final String id;
  final String teamId; // optional when it's a request-based join
  final String? requestId; // present when user joined a teamRequest
  final String userId;
  final String userName;
  final String userEmail;
  final String? userBio;
  final List<String> userSkills;
  final String message;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt;

  JoinRequestModel({
    required this.id,
    required this.teamId,
    this.requestId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userBio,
    required this.userSkills,
    required this.message,
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
  });

  factory JoinRequestModel.fromMap(String id, Map<String, dynamic> data) {
    return JoinRequestModel(
      id: id,
      teamId: data['team_id'] ?? '',
      requestId: data['request_id'],
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      userEmail: data['user_email'] ?? '',
      userBio: data['user_bio'],
      userSkills: List<String>.from(data['user_skills'] ?? []),
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['responded_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'team_id': teamId,
    if (requestId != null) 'request_id': requestId,
    'user_id': userId,
    'user_name': userName,
    'user_email': userEmail,
    'user_bio': userBio,
    'user_skills': userSkills,
    'message': message,
    'status': status,
    'created_at': Timestamp.fromDate(createdAt),
    if (respondedAt != null) 'responded_at': Timestamp.fromDate(respondedAt!),
  };
}
