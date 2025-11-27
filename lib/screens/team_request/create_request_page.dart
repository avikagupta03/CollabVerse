import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/team_request_service.dart';
import '../../services/ml_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({Key? key}) : super(key: key);


  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}


class _CreateRequestPageState extends State<CreateRequestPage> {
  final skillsCtrl = TextEditingController();
  final sizeCtrl = TextEditingController(text: '3');
  final descCtrl = TextEditingController();
  bool loading = false;


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(decoration: const InputDecoration(labelText: 'Required skills'), controller: skillsCtrl),
          TextField(decoration: const InputDecoration(labelText: 'Team size'), controller: sizeCtrl),
          TextField(decoration: const InputDecoration(labelText: 'Project description'), controller: descCtrl),
          const SizedBox(height: 12),
          loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: () async {
              setState(() => loading = true);
              final req = {
                'required_skills': skillsCtrl.text.split(',').map((e) => e.trim()).toList(),
                'team_size': int.tryParse(sizeCtrl.text) ?? 3,
                'description': descCtrl.text
              };
              final id = await TeamRequestService().createRequest(req);
              final suggestions = await MlApiService.getSuggestions(req);
              await FirebaseFirestore.instance.collection('teamRequests').doc(id).update({'suggested_teams': suggestions});
              setState(() => loading = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team request created')));
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}