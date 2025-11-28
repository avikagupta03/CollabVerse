import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/animated_loading_button.dart';
import '../../widgets/progress_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final nameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final skillsCtrl = TextEditingController();
  final interestsCtrl = TextEditingController();
  final experienceCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _userEmail;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    load();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    skillsCtrl.dispose();
    interestsCtrl.dispose();
    experienceCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _userEmail = user.email;
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
      }
      setState(() {});
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'email': _userEmail,
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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          elevation: 0,
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
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
            // Profile Header Card
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Experience Level
            _buildExperienceCard(),
            const SizedBox(height: 24),

            // Form Section
            _buildFormSection(),
            const SizedBox(height: 24),

            // Save Button
            _buildSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple, Colors.deepPurple.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameCtrl.text.isEmpty ? 'Add your name' : nameCtrl.text,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail ?? 'Email loading...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bioCtrl.text.isNotEmpty)
              Text(
                bioCtrl.text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceCard() {
    final experience = int.tryParse(experienceCtrl.text) ?? 0;
    final maxExperience = 20;
    final progress = ((experience / maxExperience).clamp(0.0, 1.0)).toDouble();

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experience Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            ProgressBar(
              progress: progress,
              label: '$experience years',
              progressColor: Colors.deepPurple,
              backgroundColor: Colors.purple.shade100,
              height: 10,
            ),
            const SizedBox(height: 12),
            Text(
              _getExperienceLabel(experience),
              style: TextStyle(
                fontSize: 12,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExperienceLabel(int years) {
    if (years == 0) return 'Beginner';
    if (years < 2) return 'Junior';
    if (years < 5) return 'Mid-level';
    if (years < 10) return 'Senior';
    return 'Expert';
  }

  Widget _buildFormSection() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              controller: nameCtrl,
              label: 'Full Name',
              icon: Icons.person,
              hint: 'Enter your full name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: bioCtrl,
              label: 'Bio',
              icon: Icons.description,
              hint: 'Tell us about yourself',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: skillsCtrl,
              label: 'Skills',
              icon: Icons.star,
              hint: 'e.g., Flutter, Firebase, Dart (comma separated)',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: interestsCtrl,
              label: 'Interests',
              icon: Icons.favorite,
              hint: 'e.g., Mobile Dev, Cloud, AI (comma separated)',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: experienceCtrl,
              label: 'Years of Experience',
              icon: Icons.work,
              hint: 'Enter number of years',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
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
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        filled: true,
        fillColor: Colors.purple.shade50.withOpacity(0.5),
        labelStyle: const TextStyle(color: Colors.deepPurple),
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
      child: AnimatedLoadingButton(
        label: 'Save Profile',
        isLoading: _isSaving,
        backgroundColor: Colors.transparent,
        onPressed: _saveProfile,
      ),
    );
  }
}
