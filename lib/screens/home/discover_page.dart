import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/skill_similarity_calculator.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../services/connectivity_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final _profileService = ProfileService();
  UserProfile? _currentUserProfile;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() => _currentUserId = user.uid);
        final snapshot = await _profileService.getProfile(user.uid).first;
        if (snapshot.exists) {
          setState(() {
            _currentUserProfile = UserProfile.fromFirestore(snapshot);
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Silently handle error - just won't have user profile for sorting
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityService = ConnectivityService();

    return Scaffold(
      body: StreamBuilder<bool>(
        stream: connectivityService.connectionStatus,
        initialData: connectivityService.isConnected,
        builder: (context, snapshot) {
          final isConnected = snapshot.data ?? true;

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
                // Connectivity indicator
                if (!isConnected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade300,
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connection lost. Some features may not work.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isConnected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.green.shade300,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_done, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Connected',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find Your Team Partner',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Browse and join team requests from other developers',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 12),
                            // Show logged-in user info
                            if (_currentUserId != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.deepPurple.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_circle,
                                      size: 18,
                                      color: Colors.deepPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Your ID: ${_currentUserId!.substring(0, 8).toUpperCase()}...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.deepPurple,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_currentUserProfile
                                            ?.skills
                                            .isNotEmpty ??
                                        false)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '${_currentUserProfile?.skills.length} Skills',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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
                            hintText: 'Search by project title or skills...',
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
                      // Team Requests List
                      Expanded(child: _buildTeamRequestsList()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamRequestsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('teamRequests')
          .orderBy('created_at', descending: true)
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
                  'Loading team requests...',
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
                  'Error loading requests',
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

        // No data state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Filter requests based on search
        final docs = snapshot.data!.docs;
        final filteredRequests = docs.where((doc) {
          final data = doc.data();
          final title = (data['description'] ?? '').toString().toLowerCase();
          final skills = List<String>.from(
            data['required_skills'] ?? [],
          ).join(' ').toLowerCase();
          return _searchQuery.isEmpty ||
              title.contains(_searchQuery) ||
              skills.contains(_searchQuery);
        }).toList();

        // Sort by semantic skill similarity if user profile is available
        // Using keyword-based similarity for now (fast local matching)
        // TODO: Integrate SemanticSkillMatcher for AI-powered matching when Hugging Face token is configured
        if (_currentUserProfile != null &&
            _currentUserProfile!.skills.isNotEmpty) {
          filteredRequests.sort((a, b) {
            final aSkills = List<String>.from(
              a.data()['required_skills'] ?? [],
            );
            final bSkills = List<String>.from(
              b.data()['required_skills'] ?? [],
            );

            final aSimilarity = SkillSimilarityCalculator.calculateSimilarity(
              _currentUserProfile!.skills,
              aSkills,
            );
            final bSimilarity = SkillSimilarityCalculator.calculateSimilarity(
              _currentUserProfile!.skills,
              bSkills,
            );

            // Sort descending (highest similarity first)
            return bSimilarity.compareTo(aSimilarity);
          });
        }

        // No search results
        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No matches found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Display requests
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final doc = filteredRequests[index];
            final data = doc.data();
            return _buildTeamRequestCard(context, data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.group_add,
                  size: 60,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Team Requests Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'There are currently no team requests available.\nStart by creating a new team request to get discovered!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to Create Request page (HomeScreen tab 2)
                  // This will be handled by parent HomeScreen
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Your Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRequestCard(
    BuildContext context,
    Map<String, dynamic> data,
    String requestId,
  ) {
    final description = data['description'] ?? 'No description';
    final requiredSkills = List<String>.from(data['required_skills'] ?? []);
    final teamSize = data['team_size'] ?? 2;
    final status = data['status'] ?? 'Open';
    final createdAt = data['created_at'] as Timestamp?;
    final creatorName = data['creator_name'] ?? 'Team Captain';

    // Calculate skill similarity with current user
    double skillMatchPercentage = 0;
    List<String> matchingSkills = [];
    if (_currentUserProfile != null && _currentUserProfile!.skills.isNotEmpty) {
      skillMatchPercentage = SkillSimilarityCalculator.calculateSimilarity(
        _currentUserProfile!.skills,
        requiredSkills,
      );
      matchingSkills = SkillSimilarityCalculator.getMatchingSkills(
        _currentUserProfile!.skills,
        requiredSkills,
      );
    }

    // Format date
    String formattedDate = 'Recently';
    if (createdAt != null) {
      final date = createdAt.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        formattedDate = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        formattedDate = '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        formattedDate = '${diff.inDays}d ago';
      } else {
        formattedDate = '${date.month}/${date.day}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request: $description'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Led by $creatorName',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Skill match indicator (if user profile exists)
              if (_currentUserProfile != null && requiredSkills.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getMatchColor(
                      skillMatchPercentage,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getMatchColor(
                        skillMatchPercentage,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: _getMatchColor(skillMatchPercentage),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Skill Match',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Text(
                            '${skillMatchPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _getMatchColor(skillMatchPercentage),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: skillMatchPercentage / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(
                            _getMatchColor(skillMatchPercentage),
                          ),
                        ),
                      ),
                      if (matchingSkills.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: matchingSkills.take(3).map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getMatchColor(
                                  skillMatchPercentage,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                skill,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getMatchColor(skillMatchPercentage),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Team size and skills
              Row(
                children: [
                  // Team size
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Team of $teamSize',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Skills count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${requiredSkills.length} skills',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Skills chips
              if (requiredSkills.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: requiredSkills.take(3).map((skill) {
                    final isMatched = matchingSkills
                        .map((s) => s.toLowerCase())
                        .contains(skill.toLowerCase());
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isMatched
                            ? Colors.green.shade100
                            : Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isMatched
                              ? Colors.green.shade700
                              : Colors.purple.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (requiredSkills.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+${requiredSkills.length - 3} more',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],

              // Join button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Joined request: $description'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Join',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'hiring':
        return Colors.blue;
      case 'active':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.deepPurple;
    }
  }

  /// Get color based on skill match percentage
  Color _getMatchColor(double percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 50) {
      return Colors.amber;
    } else if (percentage > 0) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
}
