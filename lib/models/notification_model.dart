import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String
  type; // 'team_invitation', 'task_assigned', 'message', 'team_update'
  final String? relatedId; // team_id, task_id, etc.
  final DateTime timestamp;
  final bool isRead;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.timestamp,
    this.isRead = false,
  });

  factory Notification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Notification(
      id: doc.id,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'team_update',
      relatedId: data['related_id'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'title': title,
    'message': message,
    'type': type,
    'related_id': relatedId,
    'timestamp': Timestamp.fromDate(timestamp),
    'is_read': isRead,
  };
}
