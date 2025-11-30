import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '../team_request/create_request_page.dart';
import '../teams/my_teams_page.dart';
import '../../widgets/crewcraft_logo.dart';
import 'discover_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final pages = const [
    DiscoverPage(),
    CreateRequestPage(),
    MyTeamsPage(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const CrewCraftLogo(size: 36), centerTitle: false),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: "Discover"),
          NavigationDestination(icon: Icon(Icons.add), label: "Create"),
          NavigationDestination(icon: Icon(Icons.group), label: "Teams"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
        onDestinationSelected: (i) => setState(() => index = i),
      ),
    );
  }
}
