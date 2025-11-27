import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SuggestionsPage extends StatelessWidget {
  final String requestId;
  const SuggestionsPage({Key? key, required this.requestId}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('teamRequests').doc(requestId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data();
        final suggestions = data?['suggested_teams'] ?? [];
        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, i) {
            final s = suggestions[i];
            return ListTile(
              title: Text('Team Suggestion ${i + 1}'),
              subtitle: Text('Members: ${s['members']}'),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('Create Team'),
              ),
            );
          },
        );
      },
    );
  }
}