import 'package:flutter/material.dart';
import 'chat_view.dart';
import 'kanban_view.dart';


class TeamDashboard extends StatefulWidget {
  final String teamId;
  final Map<String, dynamic> teamData;
  const TeamDashboard({Key? key, required this.teamId, required this.teamData}) : super(key: key);


  @override
  State<TeamDashboard> createState() => _TeamDashboardState();
}


class _TeamDashboardState extends State<TeamDashboard> {
  int index = 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.teamData['project_name'] ?? widget.teamData['name'])),
      body: index == 0 ? ChatView(teamId: widget.teamId) : KanbanView(teamId: widget.teamId),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.task), label: 'Tasks'),
        ],
      ),
    );
  }
}