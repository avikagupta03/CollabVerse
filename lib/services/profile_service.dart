import 'package:cloud_firestore/cloud_firestore.dart';


class ProfileService {
  final _fs = FirebaseFirestore.instance;


  Future<void> saveProfile(String uid, Map<String, dynamic> data) async {
    await _fs.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }


  Stream<DocumentSnapshot<Map<String, dynamic>>> getProfile(String uid) {
    return _fs.collection('users').doc(uid).snapshots();
  }
}