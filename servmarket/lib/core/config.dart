import 'package:flutter/foundation.dart';

class AppConfig {
  // Enable/disable features for development
  static const bool enableDebugLogging = kDebugMode;

  // Mock data for development when Firebase is not available
  static const bool useMockData = false;

  // Map provider (google_maps_flutter or flutter_map)
  static const String mapProvider = 'flutter_map'; // or 'google_maps'

  // Default location (used when geolocation is denied)
  static const double defaultLatitude = 48.8566; // Paris
  static const double defaultLongitude = 2.3522;
  static const String defaultLocationName = 'Dakar, Senegal';
}
