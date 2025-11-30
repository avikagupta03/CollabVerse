import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  List<Map<String, dynamic>> tasks = [];
  bool loading = false;


  Stream<QuerySnapshot<Map<String, dynamic>>> watchTasks(String teamId) {
    return _fs.collection('teams').doc(teamId).collection('tasks').snapshots();
  }


  Future<void> addTask(String teamId, String title) async {
    await _fs.collection('teams').doc(teamId).collection('tasks').add({
      'title': title,
      'status': 'todo',
      'created_at': FieldValue.serverTimestamp(),
    });
  }


  Future<void> updateTask(String teamId, String taskId, String status) async {
    await _fs.collection('teams').doc(teamId).collection('tasks').doc(taskId).update({'status': status});
  }
}