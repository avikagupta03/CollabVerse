import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityService {
  final _fs = FirebaseFirestore.instance;

  /// Log an activity
  Future<void> logActivity({
    required String teamId,
    required String userId,
    required String userName,
    required String actionType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _fs.collection('teams').doc(teamId).collection('activities').add({
        'user_id': userId,
        'user_name': userName,
        'action_type': actionType,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata,
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  /// Get activity feed for a team
  Stream<QuerySnapshot<Map<String, dynamic>>> getActivityFeed(String teamId) {
    return _fs
        .collection('teams')
        .doc(teamId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Get activities for a specific user in a team
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserActivities(
    String teamId,
    String userId,
  ) {
    return _fs
        .collection('teams')
        .doc(teamId)
        .collection('activities')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Get specific action types
  Stream<QuerySnapshot<Map<String, dynamic>>> getActionActivities(
    String teamId,
    String actionType,
  ) {
    return _fs
        .collection('teams')
        .doc(teamId)
        .collection('activities')
        .where('action_type', isEqualTo: actionType)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }
}
