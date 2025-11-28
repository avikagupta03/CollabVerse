import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/task_allocation_model.dart';
import '../../services/task_allocation_service.dart';
import '../../services/profile_service.dart';

class TaskAllocationPage extends StatefulWidget {
  final String teamId;
  final List<String> teamMemberIds;

  const TaskAllocationPage({
    Key? key,
    required this.teamId,
    required this.teamMemberIds,
  }) : super(key: key);

  @override
  State<TaskAllocationPage> createState() => _TaskAllocationPageState();
}

class _TaskAllocationPageState extends State<TaskAllocationPage> {
  final _requirementController = TextEditingController();
  final _allocationService = TaskAllocationService();
  final _profileService = ProfileService();

  TaskAllocation? _allocation;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _requirementController.dispose();
    super.dispose();
  }

  Future<void> _performAllocation() async {
    if (_requirementController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter project requirements')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch team member profiles
      final members = <UserProfile>[];
      for (final memberId in widget.teamMemberIds) {
        final snapshot = await _profileService.getProfile(memberId).first;
        if (snapshot.exists) {
          final member = UserProfile.fromFirestore(snapshot);
          members.add(member);
        }
      }

      if (members.isEmpty) {
        throw Exception('No team members found');
      }

      // Perform smart allocation
      final result = await _allocationService.smartAllocateTasks(
        projectRequirement: _requirementController.text,
        teamMembers: members,
        teamId: widget.teamId,
      );

      setState(() {
        _allocation = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Task Allocation'), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Requirements Input Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Requirements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _requirementController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              'Describe your project requirements...\n\n'
                              'Examples:\n'
                              '• Build a mobile app with Flutter UI and Firebase backend\n'
                              '• Implement ML model for predictions and add testing\n'
                              '• Full-stack development with deployment',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.blue[600],
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _isLoading
                                ? 'Allocating Tasks...'
                                : 'Smart Allocate Tasks',
                          ),
                          onPressed: _isLoading ? null : _performAllocation,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue[600],
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),

              // Allocation Results
              if (_allocation != null) ...[
                _buildAllocationSummary(),
                const SizedBox(height: 24),
                _buildTasksList(),
                const SizedBox(height: 24),
                _buildMemberAllocations(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build allocation summary card
  Widget _buildAllocationSummary() {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Allocation Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard(
                  'Total Tasks',
                  _allocation!.generatedTasks.length.toString(),
                  Icons.assignment,
                ),
                _buildSummaryCard(
                  'Team Members',
                  _allocation!.allocations.length.toString(),
                  Icons.people,
                ),
                _buildSummaryCard(
                  'Total Hours',
                  _allocation!.getTotalEstimatedHours().toString(),
                  Icons.schedule,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Confidence Score
            Row(
              children: [
                const Text(
                  'Confidence Score: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _allocation!.confidenceScore / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        _allocation!.confidenceScore > 75
                            ? Colors.green
                            : _allocation!.confidenceScore > 50
                            ? Colors.amber
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_allocation!.confidenceScore.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual summary card
  Widget _buildSummaryCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue[600]),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// Build tasks list
  Widget _buildTasksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Generated Tasks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allocation!.generatedTasks.length,
          itemBuilder: (context, index) {
            final task = _allocation!.generatedTasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(task.category),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            task.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            task.priority,
                            style: TextStyle(
                              color: Colors.amber[900],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${task.estimatedHours}h',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.assignedToName == 'Unassigned'
                                ? 'Unassigned'
                                : task.assignedToName,
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (task.requiredSkills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: task.requiredSkills
                            .take(3)
                            .map(
                              (skill) => Chip(
                                label: Text(skill),
                                backgroundColor: Colors.blue[100],
                                labelStyle: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 12,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build member allocations
  Widget _buildMemberAllocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Allocation by Member',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allocation!.allocations.length,
          itemBuilder: (context, index) {
            final allocation = _allocation!.allocations[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[600],
                      child: Text(
                        allocation.memberName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allocation.memberName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${allocation.getTaskCount()} tasks • ${allocation.getTotalHours()}h',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${allocation.matchPercentage.toStringAsFixed(0)}% match',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Tasks:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...allocation.tasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    task.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${task.estimatedHours} hours',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Skills:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: allocation.availableSkills
                              .map(
                                (skill) => Chip(
                                  label: Text(skill),
                                  backgroundColor: Colors.blue[100],
                                  labelStyle: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 11,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Get category color
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'UI':
        return Colors.purple[600]!;
      case 'Backend':
        return Colors.blue[600]!;
      case 'ML':
        return Colors.orange[600]!;
      case 'Testing':
        return Colors.green[600]!;
      case 'DevOps':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
