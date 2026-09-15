class AppConstants {
  // Firestore collections
  static const String usersCollection = 'users';
  static const String providersCollection = 'providers';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';

  // Storage
  static const String providerImagesStoragePath = 'provider_images';

  // Default search radius in kilometers
  static const double defaultSearchRadiusKm = 10.0;
  static const double minSearchRadiusKm = 1.0;
  static const double maxSearchRadiusKm = 100.0;

  // Geohash precision for spatial queries (higher = more precise, more queries)
  static const int geohashPrecision = 6;

  // Message constraints
  static const int maxMessageLength = 1000;

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
}
