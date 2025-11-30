import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/join_request_service.dart';
import '../../models/join_request_model.dart';

class TeamMembersView extends StatelessWidget {
  final String teamId;
  final Map<String, dynamic> teamData;

  const TeamMembersView({
    super.key,
    required this.teamId,
    required this.teamData,
  });

  @override
  Widget build(BuildContext context) {
    final members = List<String>.from(teamData['members'] ?? []);
    final leaderId = teamData['leader_id'] ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepPurple.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Team Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.blue.shade400],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.group,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  teamData['name'] ?? 'Team',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${members.length} ${members.length == 1 ? "Member" : "Members"}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Pending Requests Section (only for leader)
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              final currentUserId = authSnapshot.data?.uid;
              
              if (currentUserId == leaderId) {
                return StreamBuilder<List<JoinRequestModel>>(
                  stream: JoinRequestService().getTeamRequests(teamId),
                  builder: (context, requestSnapshot) {
                    final pendingCount = requestSnapshot.data?.length ?? 0;
                    
                    if (pendingCount > 0) {
                      return Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade100, Colors.deepOrange.shade50],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300, width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$pendingCount Pending Request${pendingCount > 1 ? "s" : ""}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Review join requests for this team',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.deepOrange,
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Project Description and Required Skills
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if ((teamData['description'] ?? '').toString().isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.description, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Project Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    teamData['description'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 16),
                ],

                // Required Skills
                if ((teamData['skills'] ?? []).isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.build, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Required Skills',
                        style: TextStyle(
                          fontSize: 14,
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
                    children: List<String>.from(teamData['skills'] ?? []).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.indigo.shade400]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Members List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final memberId = members[index];
                final isLeader = memberId == leaderId;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(memberId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: const Text('Loading...'),
                        ),
                      );
                    }

                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    final name = userData?['name'] ?? 'Unknown User';
                    final email = userData?['email'] ?? '';
                    final bio = userData?['bio'] ?? '';
                    final skills = List<String>.from(userData?['skills'] ?? []);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: isLeader 
                                  ? Colors.amber.shade100 
                                  : Colors.deepPurple.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isLeader 
                                      ? Colors.amber.shade700 
                                      : Colors.deepPurple.shade700,
                                ),
                              ),
                            ),
                            if (isLeader)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isLeader) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Text(
                                  'LEADER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                
                                // Bio Section
                                if (bio.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Bio',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    bio,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Skills Section
                                if (skills.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_outline,
                                        size: 18,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Skills',
                                        style: TextStyle(
                                          fontSize: 14,
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
                                    children: skills.map((skill) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade400,
                                              Colors.purple.shade400,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
