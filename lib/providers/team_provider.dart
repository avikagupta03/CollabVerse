import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class TeamProvider extends ChangeNotifier {
  final _fs = FirebaseFirestore.instance;
  List<Map<String, dynamic>> myTeams = [];
  bool loading = false;


  Stream<QuerySnapshot<Map<String, dynamic>>> getMyTeams(String uid) {
    return _fs.collection('teams').where('members', arrayContains: uid).snapshots();
  }


  Future<void> createTeam(String requestId, List<String> members, String name, String project) async {
    final doc = _fs.collection('teams').doc();
    await doc.set({
      'name': name,
      'project_name': project,
      'members': members,
      'created_at': FieldValue.serverTimestamp()
    });
    await _fs.collection('teamRequests').doc(requestId).update({'team_id': doc.id, 'status': 'confirmed'});
  }
}