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
    final currentUser = FirebaseAuth.instance.currentUser;
    final leaderId = currentUser?.uid;

    // Ensure creator/leader is part of the members list
    final updatedMembers = List<String>.from(members);
    if (leaderId != null && !updatedMembers.contains(leaderId)) {
      updatedMembers.add(leaderId);
    }

    // Fetch request to copy description and skills into team
    final reqSnap = await _fs.collection('teamRequests').doc(requestId).get();
    final reqData = reqSnap.data() ?? {};
    final description = reqData['description'] ?? '';
    final requiredSkills = List<String>.from(reqData['required_skills'] ?? const []);

    String _normalized(dynamic value) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
      return '';
    }

    final resolvedProject = _normalized(project).isNotEmpty
        ? _normalized(project)
        : _normalized(reqData['project_name']).isNotEmpty
            ? _normalized(reqData['project_name'])
            : _normalized(description).isNotEmpty
                ? _normalized(description)
                : 'Project';

    final resolvedName = _normalized(name).isNotEmpty
        ? _normalized(name)
        : _normalized(reqData['title']).isNotEmpty
            ? _normalized(reqData['title'])
            : resolvedProject.isNotEmpty
                ? resolvedProject
                : 'Team';

    await doc.set({
      'name': resolvedName,
      'project_name': resolvedProject,
      'description': description,
      'skills': requiredSkills,
      'members': updatedMembers,
      'leader_id': leaderId ?? '',
      'created_at': FieldValue.serverTimestamp()
    });
    await _fs.collection('teamRequests').doc(requestId).update({'team_id': doc.id, 'status': 'confirmed'});
  }
}