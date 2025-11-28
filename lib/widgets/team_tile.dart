import 'package:flutter/material.dart';

class TeamTile extends StatelessWidget {
  final String title;
  final int members;
  final VoidCallback onTap;
  const TeamTile({super.key, required this.title, required this.members, required this.onTap});


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text("Members: $members"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}