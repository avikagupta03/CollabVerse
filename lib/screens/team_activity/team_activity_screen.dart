import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/activity_service.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/empty_state.dart';

class TeamActivityScreen extends StatelessWidget {
  final String teamId;
  final String teamName;

  const TeamActivityScreen({
    Key? key,
    required this.teamId,
    required this.teamName,
  }) : super(key: key);

  IconData _getIconForAction(String actionType) {
    switch (actionType) {
      case 'joined':
        return Icons.person_add;
      case 'created_task':
        return Icons.add_task;
      case 'completed_task':
        return Icons.task_alt;
      case 'message':
        return Icons.chat;
      case 'updated_profile':
        return Icons.edit;
      default:
        return Icons.info;
    }
  }

  Color _getColorForAction(String actionType) {
    switch (actionType) {
      case 'joined':
        return Colors.green;
      case 'created_task':
        return Colors.blue;
      case 'completed_task':
        return Colors.teal;
      case 'message':
        return Colors.purple;
      case 'updated_profile':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityService = ActivityService();

    return Scaffold(
      appBar: AppBar(title: Text('$teamName Activity'), elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: activityService.getActivityFeed(teamId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: 'No activity yet',
              description: 'Team activities will appear here',
            );
          }

          final activities = snapshot.data!.docs;

          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activityData =
                  activities[index].data() as Map<String, dynamic>;
              final actionType = activityData['action_type'] ?? 'unknown';

              return ActivityTile(
                userName: activityData['user_name'] ?? 'Unknown',
                actionType: actionType,
                description: activityData['description'] ?? '',
                timestamp:
                    (activityData['timestamp'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                icon: _getIconForAction(actionType),
                iconColor: _getColorForAction(actionType),
              );
            },
          );
        },
      ),
    );
  }
}
