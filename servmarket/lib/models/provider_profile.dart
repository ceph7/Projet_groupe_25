import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentSnapshot, FieldValue, Timestamp;

/// Profil d'un prestataire stocké dans Firestore.
class ProviderProfile {
  const ProviderProfile({
    this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.phone,
    this.email,
    this.category,
    this.address,
    this.isPublished = false,
    this.createdAt,
    this.updatedAt,
  });

  /// ID du document Firestore.
  final String? id;

  /// UID de l'utilisateur propriétaire du profil.
  final String ownerId;

  /// Nom du prestataire ou de l'entreprise.
  final String name;

  final String? description;
  final String? phone;
  final String? email;
  final String? category;
  final String? address;

  /// Indique si le prestataire est visible publiquement.
  final bool isPublished;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Crée un ProviderProfile depuis un document Firestore.
  factory ProviderProfile.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snap,
      ) {
    final data = snap.data() ?? <String, dynamic>{};

    return ProviderProfile(
      id: snap.id,
      ownerId: (data['ownerId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      description: data['description'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      category: data['category'] as String?,
      address: data['address'] as String?,
      isPublished: (data['isPublished'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertit le profil en Map pour Firestore.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'ownerId': ownerId,
    'name': name,
    'description': description,
    'phone': phone,
    'email': email,
    'category': category,
    'address': address,
    'isPublished': isPublished,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  ProviderProfile copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? phone,
    String? email,
    String? category,
    String? address,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      category: category ?? this.category,
      address: address ?? this.address,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}