import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String userId;
  final String userName;
  final String teamId;
  final String
  actionType; // 'joined', 'created_task', 'completed_task', 'message', 'updated_profile'
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.teamId,
    required this.actionType,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityLog(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'Unknown',
      teamId: data['team_id'] ?? '',
      actionType: data['action_type'] ?? 'unknown',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'user_name': userName,
    'team_id': teamId,
    'action_type': actionType,
    'description': description,
    'timestamp': Timestamp.fromDate(timestamp),
    'metadata': metadata,
  };
}
