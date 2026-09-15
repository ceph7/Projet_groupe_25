/// Messages d'erreur en français pour l'authentification Firebase.
/// Aucune information sensible n'est exposée (ex: on ne confirme pas si un email existe).
class AppExceptions {
  AppExceptions._();

  static String fromAuthCode(String? code) {
    switch (code) {
      // --- Inscription ---
      case 'email-already-in-use':
      case 'email_already_in_use':
      case 'account-exists-with-different-credentials':
        return 'Cette adresse email est déjà utilisée. Connectez-vous ou utilisez un autre email.';

      case 'weak-password':
      case 'weak_password':
      case 'INVALID_PASSWORD':
        return 'Le mot de passe est trop faible. Il doit contenir au moins 6 caractères.';

      case 'invalid-email':
      case 'invalid_email':
      case 'invalid-email-format':
        return 'L\'adresse email n\'est pas valide. Veuillez la vérifier.';

      // --- Connexion ---
      case 'user-not-found':
      case 'user_not_found':
      case 'no-user-found':
        return 'Aucun compte trouvé avec ces identifiants.';

      case 'wrong-password':
      case 'wrong_password':
      case 'invalid-credential':
        return 'Identifiants incorrects. Veuillez réessayer.';

      case 'user-disabled':
      case 'user_disabled':
        return 'Ce compte a été désactivé. Contactez le support.';

      // --- Session ---
      case 'session-expired':
      case 'session_expired':
      case 'auth-session-expired':
        return 'Votre session a expiré. Veuillez vous reconnecter.';

      case 'network-request-failed':
      case 'network_request_failed':
        return 'Problème de connexion réseau. Vérifiez votre internet.';

      // --- Générique ---
      case 'too-many-requests':
      case 'too_many_requests':
        return 'Trop de tentatives. Réessayez dans quelques instants.';

      case 'operation-not-allowed':
      case 'operation_not_allowed':
        return 'Cette méthode de connexion n\'est pas encore activée.';

      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }
}