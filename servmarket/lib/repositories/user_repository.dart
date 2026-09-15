import '../models/user_profile.dart';
import '../services/firestore_service.dart';

/// Repository d'accès aux données utilisateur.
/// Isole les requêtes Firestore liées aux profils utilisateurs.
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final FirestoreService _firestore = FirestoreService.instance;

  /// Écoute le profil de l'utilisateur en temps réel.
  Stream<UserProfile?> watchUserProfile(String uid) {
    return _firestore.watchUserProfile(uid);
  }

  /// Récupère le profil d'un utilisateur.
  Future<UserProfile?> getUserProfile(String uid) {
    return _firestore.getUserProfile(uid);
  }

  /// Crée ou met à jour le profil utilisateur.
  Future<void> setUserProfile(UserProfile profile) {
    return _firestore.setUserProfile(profile);
  }
}
