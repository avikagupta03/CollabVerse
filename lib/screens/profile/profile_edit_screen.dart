import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController bioCtrl;
  late TextEditingController skillsCtrl;
  late TextEditingController interestsCtrl;
  late TextEditingController experienceCtrl;
  late TextEditingController roleCtrl;

  bool _isLoading = false;
  bool _isSaving = false;
  String _selectedRole = 'Developer';
  final List<String> _roles = [
    'Developer',
    'Designer',
    'Manager',
    'Product Owner',
    'QA Engineer',
  ];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    bioCtrl = TextEditingController();
    skillsCtrl = TextEditingController();
    interestsCtrl = TextEditingController();
    experienceCtrl = TextEditingController();
    roleCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    skillsCtrl.dispose();
    interestsCtrl.dispose();
    experienceCtrl.dispose();
    roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        nameCtrl.text = data['name'] ?? '';
        bioCtrl.text = data['bio'] ?? '';
        skillsCtrl.text = (data['skills'] ?? []).join(', ');
        interestsCtrl.text = (data['interests'] ?? []).join(', ');
        experienceCtrl.text = (data['experience'] ?? 0).toString();
        _selectedRole = data['role'] ?? 'Developer';
        roleCtrl.text = _selectedRole;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (nameCtrl.text.trim().isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'role': _selectedRole,
        'skills': skillsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'interests': interestsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'experience': int.tryParse(experienceCtrl.text) ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error saving profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.deepPurple,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _buildInputField(
              controller: nameCtrl,
              label: 'Full Name',
              icon: Icons.person,
              hint: 'Enter your full name',
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: bioCtrl,
              label: 'Bio',
              icon: Icons.description,
              hint: 'Tell us about yourself',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Professional Details'),
            const SizedBox(height: 12),
            _buildRoleDropdown(),
            const SizedBox(height: 12),
            _buildInputField(
              controller: experienceCtrl,
              label: 'Years of Experience',
              icon: Icons.work,
              hint: '0-50',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Skills & Interests'),
            const SizedBox(height: 12),
            _buildInputField(
              controller: skillsCtrl,
              label: 'Skills',
              icon: Icons.star,
              hint: 'e.g., Flutter, Firebase, Dart',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: interestsCtrl,
              label: 'Interests',
              icon: Icons.favorite,
              hint: 'e.g., Mobile Dev, Cloud, AI',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 16),
            _buildCancelButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.shade200, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.purple.shade50.withOpacity(0.5),
        labelStyle: const TextStyle(color: Colors.deepPurple),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        value: _selectedRole,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
        items: _roles.map((role) {
          return DropdownMenuItem(
            value: role,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(role),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedRole = value ?? 'Developer';
            roleCtrl.text = _selectedRole;
          });
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple, Colors.deepPurple.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Saving...'),
                ],
              )
            : const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text(
        'Cancel',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
