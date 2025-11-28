import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _fs = FirebaseFirestore.instance;

  /// Send a message to a team
  Future<String> sendMessage({
    required String teamId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    try {
      final docRef = await _fs
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .add({
            'sender_uid': senderId,
            'sender_name': senderName,
            'team_id': teamId,
            'message': content,
            'timestamp': FieldValue.serverTimestamp(),
            'is_edited': false,
            'attachments': [],
          });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages stream for a team
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(String teamId) {
    return _fs
        .collection('teams')
        .doc(teamId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Edit a message
  Future<void> editMessage(
    String teamId,
    String messageId,
    String newContent,
  ) async {
    try {
      await _fs
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .doc(messageId)
          .update({
            'message': newContent,
            'is_edited': true,
            'edited_at': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String teamId, String messageId) async {
    try {
      await _fs
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get unread message count
  Future<int> getUnreadMessageCount(String teamId, DateTime since) async {
    try {
      final snapshot = await _fs
          .collection('teams')
          .doc(teamId)
          .collection('messages')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
