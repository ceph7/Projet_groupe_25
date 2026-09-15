/// Fonctions de validation réutilisables pour les formulaires.
/// Couvre l'issue #26 : Validation et normalisation du numéro de téléphone.
class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'adresse email est requise.';
    }
    final regex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Adresse email invalide.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    return null;
  }

  static String? required(String? value, {String label = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label est requis.';
    }
    return null;
  }

  /// Issue #26 : Validation et normalisation du numéro de téléphone.
  /// Accepte les formats togolais/internationaux courants (+228, 00228, ou local).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis.';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s.\-]'), '');
    final regex = RegExp(r'^(\+?\d{8,15})$');
    if (!regex.hasMatch(cleaned)) {
      return 'Numéro de téléphone invalide.';
    }
    return null;
  }

  /// Normalise un numéro saisi en un format stable pour le stockage (sans espaces/tirets).
  static String normalizePhone(String value) {
    return value.trim().replaceAll(RegExp(r'[\s.\-]'), '');
  }
}