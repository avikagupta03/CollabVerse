import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/team_request_service.dart';
import '../../services/team_matcher_service.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({Key? key}) : super(key: key);

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final captainNameCtrl = TextEditingController();
  final skillsCtrl = TextEditingController();
  final sizeCtrl = TextEditingController(text: '2');
  final descCtrl = TextEditingController();

  bool loading = false;

  Future<void> submitRequest() async {
    // Validate inputs
    if (captainNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter team captain name')),
      );
      return;
    }

    if (skillsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter required skills')),
      );
      return;
    }

    if (descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project description')),
      );
      return;
    }

    // Validate team size
    final teamSize = int.tryParse(sizeCtrl.text) ?? 2;
    if (teamSize < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team size must be at least 2')),
      );
      return;
    }

    try {
      setState(() => loading = true);

      // Get current user info
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Prepare request data with team captain name
      final req = {
        'required_skills': skillsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        'team_size': teamSize,
        'description': descCtrl.text.trim(),
        'status': 'Open',
        'creator_id': user.uid,
        'creator_name': captainNameCtrl.text.trim(),
      };

      // 2. Save request to Firestore (service handles field naming)
      final requestId = await TeamRequestService().createRequest(req);

      // 3. Generate suggestions using your internal service
      final suggestions = await TeamMatcherService().generateSuggestions(req);

      // 4. Update request with suggestions
      if (suggestions.isNotEmpty) {
        await TeamRequestService().addSuggestions(requestId, suggestions);
      }

      // Clear form
      captainNameCtrl.clear();
      skillsCtrl.clear();
      sizeCtrl.text = '2';
      descCtrl.clear();

      // Just update UI - no need to pop since this is a tab, not a full screen
      // User will see the request appear on Discover tab
    } catch (e) {
      // Silently handle error - request might still have been created
      // User can see it on Discover tab or try again
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    captainNameCtrl.dispose();
    skillsCtrl.dispose();
    sizeCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Team Request")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Team Captain Name',
                ),
                controller: captainNameCtrl,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Required skills (comma separated)',
                ),
                controller: skillsCtrl,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Team size'),
                controller: sizeCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Project description',
                ),
                controller: descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: submitRequest,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
