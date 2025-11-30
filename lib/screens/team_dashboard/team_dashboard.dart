import 'package:flutter/material.dart';
import 'chat_view.dart';
import 'kanban_view.dart';
import 'team_members_view.dart';


class TeamDashboard extends StatefulWidget {
  final String teamId;
  final Map<String, dynamic> teamData;
  const TeamDashboard({super.key, required this.teamId, required this.teamData});


  @override
  State<TeamDashboard> createState() => _TeamDashboardState();
}


class _TeamDashboardState extends State<TeamDashboard> {
  int index = 0;


  @override
  Widget build(BuildContext context) {
    Widget currentView;
    if (index == 0) {
      currentView = ChatView(teamId: widget.teamId);
    } else if (index == 1) {
      currentView = KanbanView(teamId: widget.teamId);
    } else {
      currentView = TeamMembersView(
        teamId: widget.teamId,
        teamData: widget.teamData,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.teamData['project_name'] ?? widget.teamData['name'])),
      body: currentView,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Members'),
        ],
      ),
    );
  }
}