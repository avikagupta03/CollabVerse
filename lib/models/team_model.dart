import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String projectName;
  final String description;
  final List<String> members;
  final String leaderId;
  final List<String> skills;
  final DateTime createdAt;
  final DateTime? deadline;
  final String status; // 'active', 'completed', 'on_hold'
  final int totalTasks;
  final int completedTasks;

  TeamModel({
    required this.id,
    required this.name,
    required this.projectName,
    required this.description,
    required this.members,
    required this.leaderId,
    required this.skills,
    required this.createdAt,
    this.deadline,
    this.status = 'active',
    this.totalTasks = 0,
    this.completedTasks = 0,
  });

  factory TeamModel.fromMap(String id, Map<String, dynamic> data) {
    return TeamModel(
      id: id,
      name: data['name'] ?? '',
      projectName: data['project_name'] ?? '',
      description: data['description'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      leaderId: data['leader_id'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      totalTasks: data['total_tasks'] ?? 0,
      completedTasks: data['completed_tasks'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'project_name': projectName,
    'description': description,
    'members': members,
    'leader_id': leaderId,
    'skills': skills,
    'created_at': Timestamp.fromDate(createdAt),
    'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
    'status': status,
    'total_tasks': totalTasks,
    'completed_tasks': completedTasks,
  };

  double get completionPercentage =>
      totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;
}
