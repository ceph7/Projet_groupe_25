import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Service pour gérer l'upload de fichiers vers Firebase Storage.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _providersFolder = 'providers';

  /// Upload une photo de profil vers Firebase Storage.
  /// Retourne l'URL publique de l'image uploadée.
  /// Retourne null si le bucket Storage n'est pas configuré.
  Future<String?> uploadProviderPhoto({
    required String providerId,
    required File imageFile,
  }) async {
    try {
      // Créer un nom de fichier unique avec timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${providerId}_$timestamp.jpg';

      // Référence au dossier des photos de prestataires
      final ref = _storage.ref().child('$_providersFolder/$fileName');

      // Upload du fichier
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': 'provider',
            'providerId': providerId,
          },
        ),
      );

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;

      // Récupérer l'URL publique
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Gérer spécifiquement l'erreur de bucket non configuré
      if (e.code == 'object-not-found' || e.code == 'bucket-not-found') {
        return null;
      }
      // Re-lancer les autres erreurs Firebase
      throw Exception('Erreur Firebase Storage: ${e.message}');
    } catch (e) {
      // Pour les autres erreurs (réseau, etc.), retourner null
      // au lieu de planter l'application
      return null;
    }
  }

  /// Supprime une photo de profil de Firebase Storage.
  Future<void> deleteProviderPhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'bucket-not-found') {
        return;
      }
      throw Exception('Erreur Firebase Storage: ${e.message}');
    } catch (e) {
      // Ignore errors in production
    }
  }
}
