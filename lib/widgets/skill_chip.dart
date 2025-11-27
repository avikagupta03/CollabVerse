import 'package:flutter/material.dart';

class SkillChip extends StatelessWidget {
  final String skill;
  const SkillChip({super.key, required this.skill});


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(skill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}