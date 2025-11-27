import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collabverse/screens/team_dashboard/team_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyTeamsPage extends StatelessWidget {
  const MyTeamsPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('teams').where('members', arrayContains: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return ListTile(
              title: Text(d['project_name'] ?? d['name']),
              subtitle: Text('Members: ${(d['members'] as List).length}'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDashboard(teamId: docs[i].id, teamData: d))),
            );
          },
        );
      },
    );
  }
}