import 'task_model.dart';

class TaskAllocation {
  final String projectRequirement;
  final List<Task> generatedTasks;
  final List<AllocationResult> allocations;
  final DateTime createdAt;
  final double confidenceScore;

  TaskAllocation({
    required this.projectRequirement,
    required this.generatedTasks,
    required this.allocations,
    required this.createdAt,
    required this.confidenceScore,
  });

  int getTotalEstimatedHours() {
    return generatedTasks.fold<int>(
      0,
      (total, task) => total + task.estimatedHours,
    );
  }
}

class AllocationResult {
  final String memberId;
  final String memberName;
  final List<Task> tasks;
  final double matchPercentage;
  final List<String> availableSkills;
  final String matchReason;

  AllocationResult({
    required this.memberId,
    required this.memberName,
    required this.tasks,
    required this.matchPercentage,
    required this.availableSkills,
    required this.matchReason,
  });

  int getTotalHours() {
    return tasks.fold<int>(0, (total, task) => total + task.estimatedHours);
  }

  int getTaskCount() => tasks.length;

  Map<String, dynamic> toMap() => {
    'member_id': memberId,
    'member_name': memberName,
    'tasks': tasks.map((t) => t.toMap()).toList(),
    'match_percentage': matchPercentage,
    'available_skills': availableSkills,
    'match_reason': matchReason,
  };
}
