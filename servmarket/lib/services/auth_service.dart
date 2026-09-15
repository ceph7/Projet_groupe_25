import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException, UserCredential, User;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors.dart';
import '../models/user_profile.dart';

/// Service d'authentification Firebase (email + mot de passe).
/// Toute la logique repose sur Firebase Auth, pas de logique maison.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Utilisateur Firebase actuellement connecté (null si déconnecté).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Vérifie si un compte existe déjà pour cet email (inscription).
  /// Note: fetchSignInMethodsForEmail a été supprimé dans les versions récentes.
  /// On tente une création de compte factice pour détecter l'existence.
  Future<bool> emailAlreadyRegistered(String email) async {
    try {
      // Tente de créer un utilisateur temporaire pour vérifier l'existence
      // Si l'email existe déjà, Firebase renverra 'email-already-in-use'
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'TempPass123!',
      );
      // Si ça réussit, on supprime l'utilisateur créé (email n'existait pas)
      await _auth.currentUser?.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true;
      }
      // Pour les autres erreurs (ex: weak-password, invalid-email), on considère
      // que l'email n'est pas enregistré (ou invalide).
      return false;
    }
  }

  /// Inscription avec email + mot de passe.
  /// Crée le compte Firebase Auth puis le profil applicatif dans Firestore.
  Future<UserProfile?> register({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user == null) return null;

      final profile = UserProfile(
        uid: user.uid,
        email: email,
        role: role,
        displayName: displayName,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profile.toMap());

      return profile;
    } on FirebaseAuthException catch (e) {
      throw Exception(AppExceptions.fromAuthCode(e.code));
    } on Exception catch (_) {
      throw Exception(AppExceptions.fromAuthCode(null));
    }
  }

  /// Connexion avec email + mot de passe.
  Future<UserProfile?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user == null) return null;

      // Récupère le profil applicatif (rôle stocké dans Firestore).
      final snap = await _firestore.collection('users').doc(user.uid).get();
      if (snap.exists) {
        return UserProfile.fromSnapshot(snap);
      }

      // Fallback : crée un profil par défaut si absent.
      final profile = UserProfile(
        uid: user.uid,
        email: email,
        role: UserRole.user,
      );
      await _firestore.collection('users').doc(user.uid).set(profile.toMap());
      return profile;
    } on FirebaseAuthException catch (e) {
      throw Exception(AppExceptions.fromAuthCode(e.code));
    } on Exception catch (_) {
      throw Exception(AppExceptions.fromAuthCode(null));
    }
  }

  /// Déconnexion.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Récupère le profil applicatif de l'utilisateur connecté.
  Future<UserProfile?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _firestore.collection('users').doc(user.uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromSnapshot(snap);
  }
}