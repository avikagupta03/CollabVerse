import 'package:cloud_firestore/cloud_firestore.dart';

class PermissionService {
  final _fs = FirebaseFirestore.instance;

  static const String roleAdmin = 'admin';
  static const String roleLeader = 'leader';
  static const String roleMember = 'member';

  /// Get user's role in a team
  Future<String> getUserRole(String teamId, String userId) async {
    try {
      final doc = await _fs
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .get();

      return doc.data()?['role'] ?? roleMember;
    } catch (e) {
      return roleMember;
    }
  }

  /// Check if user has permission
  Future<bool> hasPermission(
    String teamId,
    String userId,
    String requiredRole,
  ) async {
    try {
      final role = await getUserRole(teamId, userId);
      return _canPerform(role, requiredRole);
    } catch (e) {
      return false;
    }
  }

  /// Add member to team with role
  Future<void> addMember(
    String teamId,
    String userId,
    String userName,
    String role,
  ) async {
    try {
      await _fs
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .set({
            'user_id': userId,
            'user_name': userName,
            'role': role,
            'joined_at': FieldValue.serverTimestamp(),
            'permissions': _getPermissionsForRole(role),
          });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  /// Update member role
  Future<void> updateMemberRole(
    String teamId,
    String userId,
    String newRole,
  ) async {
    try {
      await _fs
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .update({
            'role': newRole,
            'permissions': _getPermissionsForRole(newRole),
          });
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  /// Remove member from team
  Future<void> removeMember(String teamId, String userId) async {
    try {
      await _fs
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Get team members
  Stream<QuerySnapshot<Map<String, dynamic>>> getTeamMembers(String teamId) {
    return _fs
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .orderBy('joined_at', descending: true)
        .snapshots();
  }

  // Helper: Check role hierarchy
  bool _canPerform(String userRole, String requiredRole) {
    const hierarchy = {
      roleAdmin: [roleAdmin, roleLeader, roleMember],
      roleLeader: [roleLeader, roleMember],
      roleMember: [roleMember],
    };

    return hierarchy[userRole]?.contains(requiredRole) ?? false;
  }

  // Helper: Get permissions based on role
  List<String> _getPermissionsForRole(String role) {
    const permissions = {
      roleAdmin: [
        'edit_team',
        'delete_team',
        'add_member',
        'remove_member',
        'manage_roles',
        'delete_tasks',
        'delete_messages',
      ],
      roleLeader: [
        'edit_team',
        'add_member',
        'create_task',
        'edit_task',
        'manage_subtasks',
      ],
      roleMember: ['create_task', 'edit_own_task', 'comment_on_task'],
    };

    return permissions[role] ?? [];
  }
}
