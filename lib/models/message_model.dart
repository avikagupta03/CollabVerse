import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderUid;
  final String senderName;
  final String teamId;
  final String message;
  final DateTime timestamp;
  final List<String>? attachments;
  final bool isEdited;
  final DateTime? editedAt;

  MessageModel({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.teamId,
    required this.message,
    required this.timestamp,
    this.attachments,
    this.isEdited = false,
    this.editedAt,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderUid: data['sender_uid'] ?? '',
      senderName: data['sender_name'] ?? 'Unknown',
      teamId: data['team_id'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachments: List<String>.from(data['attachments'] ?? []),
      isEdited: data['is_edited'] ?? false,
      editedAt: (data['edited_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'sender_uid': senderUid,
    'sender_name': senderName,
    'team_id': teamId,
    'message': message,
    'timestamp': Timestamp.fromDate(timestamp),
    'attachments': attachments,
    'is_edited': isEdited,
    'edited_at': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
  };
}
