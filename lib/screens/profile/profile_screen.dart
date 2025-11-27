import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);


  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  final nameCtrl = TextEditingController();
  final skillsCtrl = TextEditingController();
  final interestsCtrl = TextEditingController();


  @override
  void initState() {
    super.initState();
    load();
  }


  Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final d = doc.data()!;
      nameCtrl.text = d['name'] ?? '';
      skillsCtrl.text = (d['skills'] ?? []).join(', ');
      interestsCtrl.text = (d['interests'] ?? []).join(', ');
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: skillsCtrl, decoration: const InputDecoration(labelText: 'Skills')),
          TextField(controller: interestsCtrl, decoration: const InputDecoration(labelText: 'Interests')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).set({
                'name': nameCtrl.text,
                'skills': skillsCtrl.text.split(',').map((e) => e.trim()).toList(),
                'interests': interestsCtrl.text.split(',').map((e) => e.trim()).toList(),
              }, SetOptions(merge: true));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}