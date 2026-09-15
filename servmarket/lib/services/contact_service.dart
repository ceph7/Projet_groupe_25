import 'package:url_launcher/url_launcher.dart';

/// Résultat d'une tentative de lancement d'action native, pour piloter l'UI
/// en cas d'échec (issue #25 : message si action non supportée).
class ContactActionResult {
  final bool success;
  final String? errorMessage;

  ContactActionResult({required this.success, this.errorMessage});
}

/// Service centralisant les actions de contact natif.
/// Couvre les issues #22 (bouton appeler), #23 (bouton SMS), #24 (aucune
/// action automatique sans geste utilisateur), #25 (message si action non
/// supportée).
class ContactService {
  /// Issue #22 : Bouton Appeler (tel:).
  /// Issue #24 : ne se déclenche que sur un appui explicite du bouton par
  /// l'utilisateur — jamais automatiquement.
  Future<ContactActionResult> call(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    return _launch(uri);
  }

  /// Issue #23 : Bouton SMS (sms:).
  Future<ContactActionResult> sendSms(String phoneNumber) async {
    final uri = Uri(scheme: 'sms', path: phoneNumber);
    return _launch(uri);
  }

  Future<ContactActionResult> _launch(Uri uri) async {
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        // Issue #25 : message clair si l'action n'est pas supportée
        // (ex: émulateur sans application téléphone).
        return ContactActionResult(
          success: false,
          errorMessage:
              'Aucune application n\'est disponible pour effectuer cette action sur cet appareil.',
        );
      }
      final launched = await launchUrl(uri);
      return ContactActionResult(success: launched);
    } catch (_) {
      return ContactActionResult(
        success: false,
        errorMessage: 'Impossible d\'effectuer cette action pour le moment.',
      );
    }
  }
}