import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_profile.dart' as profile;

/// Service centralisant l'authentification Firebase.
/// Couvre les issues #3 (inscription/connexion), #4 (rôle applicatif),
/// #5 (messages d'erreur en français), #6 (restauration de session).
class AuthService {
  static final AuthService instance = AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  /// Issue #6 : Restauration de session — permet de savoir si un utilisateur
  /// est déjà connecté au lancement de l'app (à utiliser dans un StreamBuilder).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Issue #3 : Inscription par email/mot de passe.
  /// Issue #4 : Enregistre le rôle applicatif (client ou prestataire) dans Firestore.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final userModel = UserModel(
        uid: uid,
        email: email,
        role: role,
        displayName: displayName,
      );

      await _usersRef.doc(uid).set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateError(e.code));
    }
  }

  /// Issue #3 : Connexion par email/mot de passe.
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _usersRef.doc(credential.user!.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_translateError(e.code));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<profile.UserProfile?> getCurrentProfile() async {
    final user = await getCurrentUserProfile();
    if (user == null) return null;
    return _toProfile(user);
  }

  Future<profile.UserProfile?> register({
    required String email,
    required String password,
    required profile.UserRole role,
    String? displayName,
  }) async {
    final user = await signUp(
      email: email,
      password: password,
      displayName: displayName ?? '',
      role: role == profile.UserRole.provider
          ? UserRole.prestataire
          : UserRole.client,
    );
    return _toProfile(user);
  }

  Future<profile.UserProfile?> login({
    required String email,
    required String password,
  }) async {
    final user = await signIn(email: email, password: password);
    return user == null ? null : _toProfile(user);
  }

  Future<void> logout() => signOut();

  profile.UserProfile _toProfile(UserModel user) {
    return profile.UserProfile(
      uid: user.uid,
      email: user.email,
      role: user.role == UserRole.prestataire
          ? profile.UserRole.provider
          : profile.UserRole.user,
      displayName: user.displayName,
    );
  }

  /// Récupère le profil complet (avec rôle) de l'utilisateur actuellement connecté.
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _usersRef.doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  /// Issue #5 : Messages d'erreur en français.
  /// Traduit les codes d'erreur techniques Firebase en messages compréhensibles.
  String _translateError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cette adresse email est déjà utilisée par un autre compte.';
      case 'invalid-email':
        return 'L\'adresse email saisie n\'est pas valide.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'user-not-found':
        return 'Aucun compte n\'est associé à cette adresse email.';
      case 'wrong-password':
        return 'Le mot de passe saisi est incorrect.';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      case 'network-request-failed':
        return 'Problème de connexion réseau. Vérifiez votre connexion internet.';
      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }
}

/// Exception personnalisée avec message d'erreur déjà traduit en français.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
