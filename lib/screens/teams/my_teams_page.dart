import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collabverse/screens/team_dashboard/team_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pending_requests_page.dart';
import '../../services/join_request_service.dart';

class MyTeamsPage extends StatefulWidget {
  const MyTeamsPage({super.key});

  @override
  State<MyTeamsPage> createState() => _MyTeamsPageState();
}

class _MyTeamsPageState extends State<MyTeamsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Teams',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage and collaborate with your teams',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      // Pending Requests Button
                      // Badge shows combined pending from teams you lead and requests you created
                      StreamBuilder<List>(
                        stream: JoinRequestService().getMyTeamRequests(),
                        builder: (context, teamSnap) {
                          final teamCount = teamSnap.data?.length ?? 0;
                          return StreamBuilder<List>(
                            stream: JoinRequestService()
                                .getMyIncomingRequestJoins(),
                            builder: (context, reqSnap) {
                              final count =
                                  teamCount + (reqSnap.data?.length ?? 0);
                              return Stack(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PendingRequestsPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                    ),
                                    iconSize: 28,
                                    color: Colors.deepPurple,
                                    tooltip: 'Pending Join Requests',
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          count > 9 ? '9+' : count.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search teams...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.deepPurple,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.purple.shade200,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Teams List
            Expanded(child: _buildTeamsList(uid)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsList(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('members', arrayContains: uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  'Loading your teams...',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading teams',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // No teams yet - Show attractive empty state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(context);
        }

        // Filter teams based on search
        final docs = snapshot.data!.docs;
        final filteredTeams = docs.where((doc) {
          final data = doc.data();
          final name = (data['project_name'] ?? data['name'] ?? '')
              .toString()
              .toLowerCase();
          return _searchQuery.isEmpty || name.contains(_searchQuery);
        }).toList();

        // No search results
        if (filteredTeams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No teams match your search',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        // Display teams
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredTeams.length,
          itemBuilder: (context, index) {
            final doc = filteredTeams[index];
            final data = doc.data();
            return _buildTeamCard(context, data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decorative illustration
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.group_add,
                  size: 70,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Teams Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You haven\'t joined any teams yet.\nBrowse and join team requests to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Once you join a team, it will appear here for easy access',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(
    BuildContext context,
    Map<String, dynamic> data,
    String teamId,
  ) {
    final rawTeamName = (data['name'] as String?)?.trim() ?? '';
    final rawProjectName = (data['project_name'] as String?)?.trim() ?? '';
    final teamName = rawTeamName.isNotEmpty
        ? rawTeamName
        : rawProjectName.isNotEmpty
        ? rawProjectName
        : 'Unnamed Team';

    final members = List<dynamic>.from(data['members'] ?? []);
    final description = data['description'] ?? 'No description';
    final projectLabel = rawProjectName.isNotEmpty ? rawProjectName : null;
    final memberCount = members.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamDashboard(teamId: teamId, teamData: data),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team name and member count
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        teamName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Team info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                        ),
                        const SizedBox(height: 4),
                        if (projectLabel != null) ...[
                          Text(
                            projectLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade300,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Member count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          memberCount.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TeamDashboard(teamId: teamId, teamData: data),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
