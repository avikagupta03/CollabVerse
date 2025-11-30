import 'package:flutter/material.dart';
import '../../services/join_request_service.dart';
import '../../models/join_request_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/team_provider.dart';

class PendingRequestsPage extends StatefulWidget {
  const PendingRequestsPage({super.key});

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  final _joinRequestService = JoinRequestService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Join Requests'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: StreamBuilder<List<JoinRequestModel>>(
          // First source: team-based pending joins
          stream: _joinRequestService.getMyTeamRequests(),
          builder: (context, teamSnap) {
            if (teamSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final teamRequests = teamSnap.data ?? [];

            // Second source: requests created by me
            return StreamBuilder<List<JoinRequestModel>>(
              stream: _joinRequestService.getMyIncomingRequestJoins(),
              builder: (context, reqSnap) {
                final incomingReqs = reqSnap.data ?? [];
                final requests = [...teamRequests, ...incomingReqs];

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending requests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join requests will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(requests[index]);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(JoinRequestModel request) {
    final hasDirectTeamId = request.teamId.isNotEmpty;

    Future<Map<String, String>> loadHeader() async {
      if (hasDirectTeamId) {
        final snap = await FirebaseFirestore.instance.collection('teams').doc(request.teamId).get();
        final data = snap.data();
        return {
          'label': 'Team',
          'name': data?['name'] ?? 'Unknown Team',
          'icon': 'group',
          'hasTeam': 'true',
        };
      } else if (request.requestId != null && request.requestId!.isNotEmpty) {
        final snap = await FirebaseFirestore.instance.collection('teamRequests').doc(request.requestId).get();
        final data = snap.data();
        final desc = data?['description'] ?? 'Team Request';
        final linkedTeamId = data?['team_id'] as String?;
        if (linkedTeamId != null && linkedTeamId.isNotEmpty) {
          // Load team name for header and mark as approvable
          final teamSnap = await FirebaseFirestore.instance.collection('teams').doc(linkedTeamId).get();
          final teamData = teamSnap.data();
          return {
            'label': 'Team',
            'name': teamData?['name'] ?? 'Unknown Team',
            'icon': 'group',
            'hasTeam': 'true',
            'teamId': linkedTeamId,
          };
        }
        return {
          'label': 'Request',
          'name': desc,
          'icon': 'list',
          'hasTeam': 'false',
        };
      }
      return {'label': 'Request', 'name': 'Pending request', 'icon': 'list', 'hasTeam': 'false'};
    }

    return FutureBuilder<Map<String, String>>(
      future: loadHeader(),
      builder: (context, headerSnap) {
        final header = headerSnap.data ?? {'label': 'Loading', 'name': 'Loading...', 'icon': 'list', 'hasTeam': 'false'};
        final teamName = header['name'] ?? 'Loading...';
        final isTeamBased = header['hasTeam'] == 'true';

        final canApprove = (header['hasTeam'] == 'true');
        final effectiveTeamId = header['teamId'] ?? request.teamId;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with team name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isTeamBased ? Icons.group : Icons.list_alt, size: 16, color: Colors.deepPurple.shade700),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          teamName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // User info section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        request.userName.isNotEmpty
                            ? request.userName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.userEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bio section
                if (request.userBio != null && request.userBio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Bio',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          request.userBio!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Skills section
                if (request.userSkills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.star_outline, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Skills',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: request.userSkills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.purple.shade400],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Message section
                if (request.message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.message_outlined, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Message',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          request.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Timestamp
                const SizedBox(height: 12),
                Text(
                  'Requested ${_formatTimestamp(request.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canApprove
                            ? () async {
                                await _joinRequestService.approveRequest(
                                  request.id,
                                  effectiveTeamId,
                                  request.userId,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${request.userName} has been added to the team!')),
                                );
                              }
                            : () => _createTeamAndApprove(request),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: Text(
                          canApprove ? 'Approve' : 'Create Team & Approve',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleReject(request),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.cancel, size: 20),
                        label: const Text(
                          'Reject',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Removed legacy _handleApprove; approval is now handled inline with teamId resolution

  Future<void> _handleReject(JoinRequestModel request) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Request'),
          content: Text(
            'Reject ${request.userName}\'s request to join?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await _joinRequestService.rejectRequest(request.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createTeamAndApprove(JoinRequestModel request) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to create a team')),
        );
        return;
      }

      // Only applicable for request-based joins (no team yet)
      if (request.requestId == null || request.requestId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This request is already linked to a team')),
        );
        return;
      }

        // Build initial team members: leader + requester
        final members = <String>{uid, request.userId}.toList();

        // Pull request metadata to seed the new team with meaningful labels
        final requestSnap = await FirebaseFirestore.instance
          .collection('teamRequests')
          .doc(request.requestId)
          .get();
        final requestData = requestSnap.data() ?? {};

        String _normalized(dynamic value) {
        if (value is String) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) return trimmed;
        }
        return '';
        }

        final requestDescription = _normalized(requestData['description']);
        final requestProjectName = _normalized(requestData['project_name']);
        final requestTitle = _normalized(requestData['title']);
        final requestCustomTeamName = _normalized(requestData['team_name']);
        final creatorName = _normalized(requestData['creator_name']);

        final defaultProjectName =
          requestProjectName.isNotEmpty
            ? requestProjectName
            : requestTitle.isNotEmpty
              ? requestTitle
              : requestDescription.isNotEmpty
                ? requestDescription
                : 'Project';

        final requesterLabel = request.userName.isNotEmpty
          ? "${request.userName.split(' ').first}'s Team"
          : 'Team by You';

        final defaultTeamName = requestCustomTeamName.isNotEmpty
            ? requestCustomTeamName
            : creatorName.isNotEmpty
                ? "${creatorName.split(' ').first}'s Team"
                : (defaultProjectName.isNotEmpty ? defaultProjectName : requesterLabel);

        final teamNameCtrl = TextEditingController(text: defaultTeamName);
        final projectNameCtrl = TextEditingController(text: defaultProjectName);

        Map<String, String>? details;
        try {
          details = await showDialog<Map<String, String>>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Create Team'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: teamNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Team name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: projectNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Project name',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, {
                        'teamName': teamNameCtrl.text.trim(),
                        'projectName': projectNameCtrl.text.trim(),
                      });
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          );
        } finally {
          teamNameCtrl.dispose();
          projectNameCtrl.dispose();
        }

        if (details == null) return;

        final selectedTeamName = details['teamName']?.trim();
        final selectedProjectName = details['projectName']?.trim();

        final teamName = (selectedTeamName != null && selectedTeamName.isNotEmpty)
            ? selectedTeamName
            : defaultTeamName;
        final projectName = (selectedProjectName != null && selectedProjectName.isNotEmpty)
            ? selectedProjectName
            : defaultProjectName;

      // Create team
      final provider = TeamProvider();
      await provider.createTeam(request.requestId!, members, teamName, projectName);

      // Read back the created team_id from the request doc
      final tr = await FirebaseFirestore.instance.collection('teamRequests').doc(request.requestId).get();
      final teamId = tr.data()?['team_id'] as String?;
      if (teamId == null || teamId.isEmpty) {
        throw Exception('Team creation did not return a team_id');
      }

      // Approve the original join request against the new team
      await _joinRequestService.approveRequest(request.id, teamId, request.userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Team created and ${request.userName} added.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating team: $e')),
      );
    }
  }
}
