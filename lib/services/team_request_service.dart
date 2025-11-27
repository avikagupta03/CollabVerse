import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';


class TeamRequestService {
  final _fs = FirebaseFirestore.instance;
  final _uuid = const Uuid();


  Future<String> createRequest(Map<String, dynamic> data) async {
    final id = _uuid.v4();
    await _fs.collection('teamRequests').doc(id).set({
      'created_at': FieldValue.serverTimestamp(),
      ...data,
    });
    return id;
  }


  Stream<DocumentSnapshot<Map<String, dynamic>>> getRequest(String id) {
    return _fs.collection('teamRequests').doc(id).snapshots();
  }
}