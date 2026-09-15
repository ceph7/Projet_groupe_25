import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

import '../core/errors.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// State management pour l'authentification.
/// Gère l'état de connexion et expose les opérations d'inscription/connexion.
class AuthProvider extends ChangeNotifier {
  AuthProvider._();
  static final AuthProvider instance = AuthProvider._();

  final AuthService _auth = AuthService.instance;

  UserProfile? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Écoute les changements d'état d'authentification.
  void init() {
    _auth.authStateChanges.listen((User? user) {
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _user = null;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _auth.getCurrentProfile();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inscription avec email, mot de passe et rôle.
  Future<bool> register({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _auth.register(
        email: email,
        password: password,
        role: role,
        displayName: displayName,
      );
      if (profile != null) {
        _user = profile;
        return true;
      }
      _errorMessage = 'L\'inscription a échoué.';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Connexion avec email et mot de passe.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _auth.login(email: email, password: password);
      if (profile != null) {
        _user = profile;
        return true;
      }
      _errorMessage = 'La connexion a échoué.';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Déconnexion.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.logout();
      _user = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
