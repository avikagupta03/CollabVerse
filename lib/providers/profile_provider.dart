import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileProvider extends ChangeNotifier {
  final _fs = FirebaseFirestore.instance;
  Map<String, dynamic>? profile;
  bool loading = false;


  Future<void> loadProfile(String uid) async {
    loading = true;
    notifyListeners();
    final doc = await _fs.collection('users').doc(uid).get();
    profile = doc.data();
    loading = false;
    notifyListeners();
  }


  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _fs.collection('users').doc(uid).set(data, SetOptions(merge: true));
    await loadProfile(uid);
  }
}