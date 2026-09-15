/// Utilitaire de calcul de geohash pour les requêtes spatiales Firestore.
/// Couvre l'issue #13 : Recherche par geohash + filtrage par distance réelle.
library;

import 'dart:math' as math;

class GeohashHelper {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode une position (latitude, longitude) en geohash.
  /// [precision] : longueur du geohash (9 = précision ~5m, suffisant pour une app locale).
  static String encode(double latitude, double longitude, {int precision = 9}) {
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    final buffer = StringBuffer();

    bool isEven = true;
    int bit = 0;
    int ch = 0;

    while (buffer.length < precision) {
      if (isEven) {
        final mid = (lonMin + lonMax) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  /// Calcule la distance en kilomètres entre deux points GPS (formule de Haversine).
  static double distanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Calcule les bornes de geohash (min/max) à requêter pour couvrir
  /// un rayon de recherche autour d'un point donné.
  /// Utilisé pour construire les requêtes Firestore (where geohash >= min && <= max).
  static Map<String, String> geohashQueryBounds(
    double latitude,
    double longitude,
    double radiusInKm,
  ) {
    // Approximation : 1 degré de latitude ≈ 111 km.
    final latDelta = radiusInKm / 111.0;
    final lonDelta = radiusInKm / (111.0 * math.cos(_degToRad(latitude)));

    final lowerLat = latitude - latDelta;
    final upperLat = latitude + latDelta;
    final lowerLon = longitude - lonDelta;
    final upperLon = longitude + lonDelta;

    return {
      'lower': encode(lowerLat, lowerLon, precision: 5),
      'upper': encode(upperLat, upperLon, precision: 5),
    };
  }
}
