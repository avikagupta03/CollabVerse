import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/join_request_model.dart';

class JoinRequestService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Create a join request for a team
  Future<void> createJoinRequest({
    required String teamId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get user profile data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    // Get team leader to route request correctly
    final teamDoc = await _firestore.collection('teams').doc(teamId).get();
    final teamData = teamDoc.data() ?? {};
    final leaderId = teamData['leader_id'] as String?;

    final joinId = _firestore.collection('join_requests').doc().id;
    final payload = {
      'id': joinId,
      'team_id': teamId,
      if (leaderId != null) 'leader_id': leaderId,
      'user_id': user.uid,
      'user_name': userData['name'] ?? user.email ?? 'Unknown User',
      'user_email': user.email ?? '',
      'user_bio': userData['bio'],
      'user_skills': List<String>.from(userData['skills'] ?? []),
      'message': message,
      'status': 'pending',
      'created_at': DateTime.now(),
    };

    await _firestore.collection('join_requests').doc(joinId).set(payload);
  }

  /// Create a join request targeted at a team request (not a team yet)
  Future<void> createJoinRequestForRequest({
    required String requestId,
    required String creatorId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final requestDoc = await _firestore.collection('teamRequests').doc(requestId).get();
    final requestData = requestDoc.data() ?? {};

    final joinId = _firestore.collection('join_requests').doc().id;

    final join = {
      'id': joinId,
      'request_id': requestId,
      'creator_id': creatorId,
      'creator_name': requestData['creator_name'] ?? '',
      'user_id': user.uid,
      'user_name': userData['name'] ?? user.email ?? 'Unknown User',
      'user_email': user.email ?? '',
      'user_bio': userData['bio'],
      'user_skills': List<String>.from(userData['skills'] ?? []),
      'message': message,
      'status': 'pending',
      'created_at': DateTime.now(),
    };

    await _firestore.collection('join_requests').doc(joinId).set(join);
  }

  /// Get pending join requests for requests created by current user
  Stream<List<JoinRequestModel>> getMyIncomingRequestJoins() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
      .collection('join_requests')
      .where('creator_id', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => JoinRequestModel.fromMap(doc.id, doc.data()))
        .toList());
  }
  /// Get all pending join requests for teams where current user is the leader
  Stream<List<JoinRequestModel>> getMyTeamRequests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    // Query join_requests directly by leader_id to avoid whereIn + index issues
    return _firestore
      .collection('join_requests')
      .where('leader_id', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => JoinRequestModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// Get join requests for a specific team
  Stream<List<JoinRequestModel>> getTeamRequests(String teamId) {
    return _firestore
        .collection('join_requests')
        .where('team_id', isEqualTo: teamId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JoinRequestModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Approve a join request and add user to team
  Future<void> approveRequest(String requestId, String teamId, String userId) async {
    // Read the join request to see if it is tied to a teamRequest
    final jrSnap = await _firestore.collection('join_requests').doc(requestId).get();
    final jrData = jrSnap.data() ?? {};
    final String? linkedRequestId = jrData['request_id'] as String?;

    final batch = _firestore.batch();

    // Update join_request status
    batch.update(
      _firestore.collection('join_requests').doc(requestId),
      {
        'status': 'approved',
        'responded_at': FieldValue.serverTimestamp(),
      },
    );

    // Add user to team members
    batch.update(
      _firestore.collection('teams').doc(teamId),
      {
        'members': FieldValue.arrayUnion([userId]),
      },
    );

    // If this approval is for a request-based join, decrement the required team members
    if (linkedRequestId != null && linkedRequestId.isNotEmpty) {
      batch.update(
        _firestore.collection('teamRequests').doc(linkedRequestId),
        {
          // Reduce the required count by 1; if the field doesn't exist, initialize to team_size - 1 on next read
          'team_size': FieldValue.increment(-1),
          'updated_at': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }

  /// Reject a join request
  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('join_requests').doc(requestId).update({
      'status': 'rejected',
      'responded_at': FieldValue.serverTimestamp(),
    });
  }

  /// Check if user has already sent a request to this team
  Future<bool> hasExistingRequest(String teamId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final snapshot = await _firestore
        .collection('join_requests')
        .where('team_id', isEqualTo: teamId)
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
