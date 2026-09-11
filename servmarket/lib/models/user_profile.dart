import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentSnapshot, FieldValue, Timestamp;

/// Rôles applicatifs supportés.
enum UserRole {
  user,
  provider,
}

extension UserRoleX on UserRole {
  String get label => name;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'provider':
        return UserRole.provider;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

/// Profil applicatif d'un utilisateur (stocké dans Firestore `users/{uid}`).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String? displayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return UserProfile(
      uid: snap.id,
      email: (data['email'] as String?) ?? '',
      role: UserRoleX.fromString(data['role'] as String?),
      displayName: data['displayName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'email': email,
        'role': role.label,
        'displayName': displayName,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  UserProfile copyWith({
    String? email,
    UserRole? role,
    String? displayName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserProfile(
        uid: uid,
        email: email ?? this.email,
        role: role ?? this.role,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}