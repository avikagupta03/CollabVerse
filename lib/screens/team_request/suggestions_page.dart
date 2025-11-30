import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/join_request_service.dart';


class SuggestionsPage extends StatelessWidget {
  final String requestId;
  const SuggestionsPage({super.key, required this.requestId});


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
            final teamId = s['team_id'];
            final teamName = s['team_name'] ?? 'Suggested Team';
            final members = s['members'];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                title: Text(teamName),
                subtitle: Text('Members: $members'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (teamId != null)
                      OutlinedButton(
                        onPressed: () async {
                          try {
                            await JoinRequestService().createJoinRequest(
                              teamId: teamId,
                              message: 'Hi! I\'d like to join your team.',
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Join request sent to team'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to send request: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Request to Join'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Existing behavior placeholder
                      },
                      child: const Text('Create Team'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}