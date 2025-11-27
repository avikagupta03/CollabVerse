import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DiscoverPage extends StatelessWidget {
  const DiscoverPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return ListTile(
              title: Text(d['name'] ?? 'User'),
              subtitle: Text((d['skills'] ?? []).join(', ')),
              leading: CircleAvatar(child: Text((d['name'] ?? 'U')[0])),
            );
          },
        );
      },
    );
  }
}