import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de données pour un prestataire de services.
/// Correspond à la collection Firestore "providers" (issue #7).
class ProviderModel {
  final String? id;
  final String ownerId;
  final String name;
  final String category;
  final String description;
  final String phone;
  final double lat;
  final double lng;
  final String geohash;
  final bool isActive; // issue #9 : fiche désactivée invisible publiquement
  final DateTime? createdAt;

  ProviderModel({
    this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    this.description = '',
    required this.phone,
    required this.lat,
    required this.lng,
    required this.geohash,
    this.isActive = true,
    this.createdAt,
  });

  /// Construit un ProviderModel à partir d'un document Firestore.
  factory ProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      phone: data['phone'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      geohash: data['geohash'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertit le modèle en Map pour l'écriture Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'category': category,
      'description': description,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'geohash': geohash,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ProviderModel copyWith({
    String? name,
    String? category,
    String? description,
    String? phone,
    double? lat,
    double? lng,
    String? geohash,
    bool? isActive,
  }) {
    return ProviderModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      geohash: geohash ?? this.geohash,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

/// Liste des catégories de service disponibles (issue #19 : filtres par catégorie).
class ServiceCategories {
  static const List<String> all = [
    'Plomberie',
    'Électricité',
    'Mécanique',
    'Coiffure',
    'Ménage',
    'Jardinage',
    'Menuiserie',
    'Peinture',
    'Informatique',
    'Autre',
  ];
}
