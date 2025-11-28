import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _fs = FirebaseFirestore.instance;

  /// Create a notification for a user
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await _fs
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'type': type,
            'related_id': relatedId,
            'timestamp': FieldValue.serverTimestamp(),
            'is_read': false,
          });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Get unread notifications for a user
  Stream<QuerySnapshot<Map<String, dynamic>>> getUnreadNotifications(
    String userId,
  ) {
    return _fs
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('is_read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get all notifications for a user
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllNotifications(
    String userId,
  ) {
    return _fs
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _fs
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _fs
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('is_read', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'is_read': true});
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _fs
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _fs
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('is_read', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
