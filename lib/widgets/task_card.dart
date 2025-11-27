import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String status;
  final VoidCallback onMoveToTodo;
  final VoidCallback onMoveToDoing;
  final VoidCallback onMoveToDone;

  const TaskCard({
    super.key,
    required this.title,
    required this.status,
    required this.onMoveToTodo,
    required this.onMoveToDoing,
    required this.onMoveToDone,
  });


  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'todo') onMoveToTodo();
            if (value == 'doing') onMoveToDoing();
            if (value == 'done') onMoveToDone();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'todo', child: Text('To-Do')),
            PopupMenuItem(value: 'doing', child: Text('Doing')),
            PopupMenuItem(value: 'done', child: Text('Done')),
          ],
        ),
      ),
    );
  }
}