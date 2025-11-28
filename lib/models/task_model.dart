import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String category; // 'UI', 'Backend', 'ML', 'DevOps', 'Testing'
  final List<String> requiredSkills;
  final String priority;
  final int estimatedHours;
  final String assignedTo;
  final String assignedToName;
  final String status;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.requiredSkills,
    required this.priority,
    required this.estimatedHours,
    required this.assignedTo,
    required this.assignedToName,
    this.status = 'Unassigned',
    required this.createdAt,
  });

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      requiredSkills: List<String>.from(data['required_skills'] ?? []),
      priority: data['priority'] ?? 'Medium',
      estimatedHours: data['estimated_hours'] ?? 0,
      assignedTo: data['assigned_to'] ?? '',
      assignedToName: data['assigned_to_name'] ?? '',
      status: data['status'] ?? 'Unassigned',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'category': category,
    'required_skills': requiredSkills,
    'priority': priority,
    'estimated_hours': estimatedHours,
    'assigned_to': assignedTo,
    'assigned_to_name': assignedToName,
    'status': status,
    'created_at': createdAt,
  };

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<String>? requiredSkills,
    String? priority,
    int? estimatedHours,
    String? assignedTo,
    String? assignedToName,
    String? status,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      priority: priority ?? this.priority,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
