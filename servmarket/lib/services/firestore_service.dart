import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider_model.dart';
import '../models/user_profile.dart';
import '../utils/geohash_helper.dart';

/// Service centralisant les opérations Firestore sur les prestataires.
/// Couvre les issues #7 (modèle), #8 (création/modification), #9 (désactivation),
/// #13 (recherche geohash), #17 (liste des résultats).
class FirestoreService {
  static final FirestoreService instance = FirestoreService();

  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference _providersRef = FirebaseFirestore.instance
      .collection('providers');

  Stream<UserProfile?> watchUserProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromSnapshot(
        snapshot as DocumentSnapshot<Map<String, dynamic>>,
      );
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    if (!snapshot.exists) return null;
    return UserProfile.fromSnapshot(
      snapshot as DocumentSnapshot<Map<String, dynamic>>,
    );
  }

  Future<void> setUserProfile(UserProfile profile) {
    return _usersRef
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<List<ProviderModel>> getProvidersByOwner(String ownerId) async {
    final snapshot = await _providersRef
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snapshot.docs
        .map((doc) => ProviderModel.fromFirestore(doc))
        .toList();
  }

  /// Issue #8 : Création et modification d'une fiche (propriétaire uniquement).
  /// Les règles Firestore (issue #27) garantissent côté serveur que seul
  /// le propriétaire (ownerId == request.auth.uid) peut écrire.
  Future<String> createProvider(ProviderModel provider) async {
    final docRef = await _providersRef.add(provider.toFirestore());
    return docRef.id;
  }

  Future<void> updateProvider(ProviderModel provider) async {
    if (provider.id == null) {
      throw ArgumentError('Impossible de mettre à jour un provider sans id');
    }
    await _providersRef.doc(provider.id).update(provider.toFirestore());
  }

  /// Issue #9 : Fiche désactivée invisible publiquement (soft delete).
  /// On ne supprime pas le document, on le marque inactif pour préserver
  /// l'historique tout en le retirant de l'annuaire public.
  Future<void> deactivateProvider(String providerId) async {
    await _providersRef.doc(providerId).update({'isActive': false});
  }

  Future<void> reactivateProvider(String providerId) async {
    await _providersRef.doc(providerId).update({'isActive': true});
  }

  /// Récupère la fiche d'un prestataire par son id.
  Future<ProviderModel?> getProviderById(String providerId) async {
    final doc = await _providersRef.doc(providerId).get();
    if (!doc.exists) return null;
    return ProviderModel.fromFirestore(doc);
  }

  /// Récupère la fiche prestataire appartenant à un utilisateur donné (pour édition).
  Future<ProviderModel?> getProviderByOwner(String ownerId) async {
    final snapshot = await _providersRef
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ProviderModel.fromFirestore(snapshot.docs.first);
  }

  /// Issue #13 : Recherche par geohash + filtrage par distance réelle.
  /// Issue #17 : Liste des résultats (cartes prestataires).
  /// Issue #19 : Filtres par catégorie (paramètre optionnel [category]).
  ///
  /// Étape 1 : requête Firestore grossière sur la plage de geohash (rapide, indexé).
  /// Étape 2 : filtrage précis en mémoire par distance réelle (Haversine),
  /// car le geohash seul peut inclure de faux positifs en bordure de zone.
  Future<List<ProviderModel>> searchNearby({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? category,
  }) async {
    final bounds = GeohashHelper.geohashQueryBounds(
      latitude,
      longitude,
      radiusInKm,
    );

    Query query = _providersRef
        .where('isActive', isEqualTo: true)
        .orderBy('geohash')
        .startAt([bounds['lower']])
        .endAt(['${bounds['upper']}~']);

    final snapshot = await query.get();

    var results = snapshot.docs
        .map((doc) => ProviderModel.fromFirestore(doc))
        .where((provider) {
          final distance = GeohashHelper.distanceInKm(
            latitude,
            longitude,
            provider.lat,
            provider.lng,
          );
          return distance <= radiusInKm;
        })
        .toList();

    // Issue #19 : filtre par catégorie appliqué après le filtrage géographique.
    if (category != null && category.isNotEmpty) {
      results = results.where((p) => p.category == category).toList();
    }

    // Tri par distance croissante (issue SPAT-03 du cahier des charges).
    results.sort((a, b) {
      final distA = GeohashHelper.distanceInKm(
        latitude,
        longitude,
        a.lat,
        a.lng,
      );
      final distB = GeohashHelper.distanceInKm(
        latitude,
        longitude,
        b.lat,
        b.lng,
      );
      return distA.compareTo(distB);
    });

    return results;
  }

  /// Issue #18 : Affichage carte avec marqueurs — flux temps réel des prestataires actifs.
  Stream<List<ProviderModel>> watchActiveProviders() {
    return _providersRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProviderModel.fromFirestore(doc))
              .toList(),
        );
  }
}
