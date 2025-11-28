import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String? bio;
  final List<String> skills;
  final List<String> interests;
  final String preferredRole;
  final int experience; // e.g. years or level
  final List<String> teamsJoined;
  final DateTime createdAt;
  final DateTime? lastActive;
  final bool isAvailable;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.bio,
    required this.skills,
    required this.interests,
    required this.preferredRole,
    required this.experience,
    this.teamsJoined = const [],
    required this.createdAt,
    this.lastActive,
    this.isAvailable = true,
  });

  /// Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photo_url'],
      bio: data['bio'],
      skills: List<String>.from(data['skills'] ?? const []),
      interests: List<String>.from(data['interests'] ?? const []),
      preferredRole: data['preferred_role'] ?? '',
      experience: (data['experience'] ?? 0) is int
          ? data['experience']
          : int.tryParse(data['experience'].toString()) ?? 0,
      teamsJoined: List<String>.from(data['teams_joined'] ?? const []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['last_active'] as Timestamp?)?.toDate(),
      isAvailable: data['is_available'] ?? true,
    );
  }

  /// To map (if you ever need to write profile to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'bio': bio,
      'skills': skills,
      'interests': interests,
      'preferred_role': preferredRole,
      'experience': experience,
      'teams_joined': teamsJoined,
      'created_at': Timestamp.fromDate(createdAt),
      'last_active': lastActive != null
          ? Timestamp.fromDate(lastActive!)
          : null,
      'is_available': isAvailable,
    };
  }

  UserProfile copyWith({
    String? name,
    String? photoUrl,
    String? bio,
    List<String>? skills,
    List<String>? interests,
    String? preferredRole,
    int? experience,
    List<String>? teamsJoined,
    bool? isAvailable,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      preferredRole: preferredRole ?? this.preferredRole,
      experience: experience ?? this.experience,
      teamsJoined: teamsJoined ?? this.teamsJoined,
      createdAt: createdAt,
      lastActive: DateTime.now(),
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
