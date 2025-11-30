import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class KanbanView extends StatelessWidget {
  final String teamId;
  const KanbanView({super.key, required this.teamId});


  @override
  Widget build(BuildContext context) {
    final tasks = FirebaseFirestore.instance.collection('teams').doc(teamId).collection('tasks');


    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(child: TextField(decoration: const InputDecoration(hintText: 'New task'), onSubmitted: (text) async {
                if (text.trim().isEmpty) return;
                await tasks.add({'title': text, 'status': 'todo', 'created_at': FieldValue.serverTimestamp()});
              })),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: tasks.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              final todo = docs.where((e) => e['status'] == 'todo').toList();
              final doing = docs.where((e) => e['status'] == 'doing').toList();
              final done = docs.where((e) => e['status'] == 'done').toList();


              return Row(
                children: [
                  Expanded(child: TaskColumn(title: 'To Do', items: todo, ref: tasks)),
                  Expanded(child: TaskColumn(title: 'Doing', items: doing, ref: tasks)),
                  Expanded(child: TaskColumn(title: 'Done', items: done, ref: tasks)),
                ],
              );
            },
          ),
        )
      ],
    );
  }
}

class TaskColumn extends StatelessWidget {
  final String title;
  final List items;
  final CollectionReference ref;
  const TaskColumn({super.key, required this.title, required this.items, required this.ref});


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final d = items[i];
              return Card(
                child: ListTile(
                  title: Text(d['title']),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async => await ref.doc(d.id).update({'status': v}),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'todo', child: Text('To Do')),
                      PopupMenuItem(value: 'doing', child: Text('Doing')),
                      PopupMenuItem(value: 'done', child: Text('Done')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}