import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class TeamRequestService {
  final _fs = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Create a team request with proper field naming and server timestamp
  Future<String> createRequest(Map<String, dynamic> data) async {
    final id = _uuid.v4();

    // Ensure consistent field names and default values
    final requestData = {
      'id': id,
      'description': data['description'] ?? '',
      'required_skills': data['required_skills'] ?? [],
      'team_size': data['team_size'] ?? 2,
      'status': data['status'] ?? 'Open',
      'suggested_teams': data['suggested_teams'] ?? [],
      'creator_id': data['creator_id'] ?? '',
      'creator_name': data['creator_name'] ?? 'Team Captain',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _fs.collection('teamRequests').doc(id).set(requestData);
    return id;
  }

  /// Get a single team request with real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> getRequest(String id) {
    return _fs.collection('teamRequests').doc(id).snapshots();
  }

  /// Get all team requests with real-time updates (ordered by creation date)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllRequests() {
    return _fs
        .collection('teamRequests')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Get team requests filtered by status
  Stream<QuerySnapshot<Map<String, dynamic>>> getRequestsByStatus(
    String status,
  ) {
    return _fs
        .collection('teamRequests')
        .where('status', isEqualTo: status)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Update a team request
  Future<void> updateRequest(String id, Map<String, dynamic> updates) async {
    updates['updated_at'] = FieldValue.serverTimestamp();
    await _fs.collection('teamRequests').doc(id).update(updates);
  }

  /// Delete a team request
  Future<void> deleteRequest(String id) async {
    await _fs.collection('teamRequests').doc(id).delete();
  }

  /// Add suggested teams to a request
  Future<void> addSuggestions(
    String requestId,
    List<dynamic> suggestions,
  ) async {
    await _fs.collection('teamRequests').doc(requestId).update({
      'suggested_teams': suggestions,
    });
  }
}
