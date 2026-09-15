import 'package:cloud_firestore/cloud_firestore.dart';

/// Rôle applicatif de l'utilisateur (issue #4).
enum UserRole { client, prestataire }

extension UserRoleExtension on UserRole {
  String get value => name;
  String get label => name;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.client,
    );
  }
}

/// Modèle de données pour un utilisateur (collection Firestore "users").
class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String displayName;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: UserRoleExtension.fromString(data['role'] ?? 'client'),
      displayName: data['displayName'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'email': email, 'role': role.value, 'displayName': displayName};
  }
}
