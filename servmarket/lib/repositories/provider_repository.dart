import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider_profile.dart';

/// Repository pour la gestion des profils de prestataires dans Firestore.
/// Isole les requêtes Firestore et gère les opérations CRUD.
class ProviderRepository {
  ProviderRepository._();
  static final ProviderRepository instance = ProviderRepository._();

  final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'providers';

  /// Crée un nouveau profil de prestataire.
  /// Le propriétaire est déterminé par l'UID Firebase de l'utilisateur connecté.
  Future<ProviderProfile?> create(ProviderProfile profile) async {
    try {
      final docRef = await _firestore.collection(_collection).add(profile.toMap());
      return profile.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }

  /// Met à jour un profil de prestataire existant.
  /// Seul le propriétaire peut modifier (vérifié par les règles Firestore).
  Future<void> update(String providerId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(providerId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Met à jour un profil complet.
  Future<void> updateProfile(ProviderProfile profile) async {
    if (profile.id == null) {
      throw Exception('ID du profil requis pour la mise à jour');
    }
    await update(profile.id!, profile.toMap());
  }

  /// Supprime un profil de prestataire (suppression logique recommandée).
  /// Préférer désactiver avec isPublished = false.
  Future<void> delete(String providerId) async {
    try {
      await _firestore.collection(_collection).doc(providerId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du profil: $e');
    }
  }

  /// Récupère un profil par son ID.
  Future<ProviderProfile?> getById(String providerId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(providerId).get();
      if (!doc.exists) return null;
      return ProviderProfile.fromSnapshot(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Récupère tous les profils d'un propriétaire.
  Future<List<ProviderProfile>> getByOwner(String ownerId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .get();
      
      return query.docs
          .map((doc) => ProviderProfile.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des profils: $e');
    }
  }

  /// Récupère les profils publiés (pour l'annuaire public).
  Future<List<ProviderProfile>> getPublished() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('isPublished', isEqualTo: true)
          .get();
      
      return query.docs
          .map((doc) => ProviderProfile.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des profils publiés: $e');
    }
  }

  /// Récupère les profils par catégorie.
  Future<List<ProviderProfile>> getByCategory(String category) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isPublished', isEqualTo: true)
          .get();
      
      return query.docs
          .map((doc) => ProviderProfile.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération par catégorie: $e');
    }
  }

  /// Stream des profils d'un propriétaire (pour UI réactive).
  Stream<List<ProviderProfile>> watchByOwner(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProviderProfile.fromSnapshot(doc))
            .toList());
  }

  /// Stream des profils publiés (pour l'annuaire public).
  Stream<List<ProviderProfile>> watchPublished() {
    return _firestore
        .collection(_collection)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProviderProfile.fromSnapshot(doc))
            .toList());
  }
}
