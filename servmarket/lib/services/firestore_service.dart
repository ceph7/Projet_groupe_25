import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/provider_profile.dart';
import '../models/user_profile.dart';

/// Service d'accès à Firestore.
/// Isole toutes les requêtes de lecture/écriture sur la base de données.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---

  Stream<UserProfile?> watchUserProfile(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromSnapshot(snap);
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final snap = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromSnapshot(snap);
  }

  Future<void> setUserProfile(UserProfile profile) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  // --- Providers ---

  Stream<List<ProviderProfile>> watchProviders() {
    return _db
        .collection(AppConstants.providersCollection)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProviderProfile.fromSnapshot(doc))
            .toList());
  }

  Future<ProviderProfile?> getProvider(String id) async {
    final snap = await _db.collection(AppConstants.providersCollection).doc(id).get();
    if (!snap.exists) return null;
    return ProviderProfile.fromSnapshot(snap);
  }

  Future<List<ProviderProfile>> getProvidersByOwner(String ownerId) async {
    final snap = await _db
        .collection(AppConstants.providersCollection)
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snap.docs.map((doc) => ProviderProfile.fromSnapshot(doc)).toList();
  }

  Future<String> createProvider(ProviderProfile provider) async {
    final doc = await _db.collection(AppConstants.providersCollection).add(provider.toMap());
    return doc.id;
  }

  Future<void> updateProvider(String id, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.providersCollection).doc(id).update(data);
  }

  Future<void> deleteProvider(String id) async {
    await _db.collection(AppConstants.providersCollection).doc(id).delete();
  }
}
