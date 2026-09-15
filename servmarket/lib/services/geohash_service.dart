import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Service pour les calculs de géohash et recherche spatiale.
/// Utilise latlong2 pour les calculs de distance et implémente le géohash manuellement.
class GeohashService {
  GeohashService._();
  static final GeohashService instance = GeohashService._();

  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Convertit des coordonnées en géohash.
  String encode(double lat, double lng, {int precision = 9}) {
    int idx = 0;
    int bit = 0;
    bool evenBit = true;
    final geohash = StringBuffer();
    double lat0 = -90.0;
    double lat1 = 90.0;
    double lng0 = -180.0;
    double lng1 = 180.0;

    while (geohash.length < precision) {
      if (evenBit) {
        double mid = (lng0 + lng1) / 2;
        if (lng > mid) {
          idx = (idx << 1) + 1;
          lng0 = mid;
        } else {
          idx = idx << 1;
          lng1 = mid;
        }
      } else {
        double mid = (lat0 + lat1) / 2;
        if (lat > mid) {
          idx = (idx << 1) + 1;
          lat0 = mid;
        } else {
          idx = idx << 1;
          lat1 = mid;
        }
      }

      evenBit = !evenBit;

      if (++bit == 5) {
        geohash.write(_base32[idx]);
        bit = 0;
        idx = 0;
      }
    }

    return geohash.toString();
  }

  /// Calcule les bornes de géohash pour une recherche circulaire.
  /// Retourne les géohashes min et max pour la requête Firestore.
  Map<String, String> calculateBounds(double lat, double lng, double radiusKm) {
    // Calculer les bornes approximatives en latitude/longitude
    // 1 degré ≈ 111 km
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * cos(lat * pi / 180));

    final minLat = lat - latDelta;
    final maxLat = lat + latDelta;
    final minLng = lng - lngDelta;
    final maxLng = lng + lngDelta;

    return {
      'minGeohash': encode(minLat, minLng, precision: 7),
      'maxGeohash': encode(maxLat, maxLng, precision: 7),
      'minLat': minLat.toString(),
      'maxLat': maxLat.toString(),
      'minLng': minLng.toString(),
      'maxLng': maxLng.toString(),
    };
  }

  /// Filtre les résultats par distance réelle (Haversine).
  /// Élimine les faux positifs de la boîte englobante rectangulaire.
  List<T> filterByDistance<T>(
    List<T> items,
    double centerLat,
    double centerLng,
    double radiusKm,
    double Function(T) getLat,
    double Function(T) getLng,
  ) {
    final filtered = <T>[];
    final distanceCalculator = const Distance();

    for (final item in items) {
      final itemLat = getLat(item);
      final itemLng = getLng(item);
      final distance = distanceCalculator.as(
        LengthUnit.Kilometer,
        LatLng(centerLat, centerLng),
        LatLng(itemLat, itemLng),
      );

      if (distance <= radiusKm) {
        filtered.add(item);
      }
    }

    // Trier par distance croissante
    filtered.sort((a, b) {
      final distA = distanceCalculator.as(
        LengthUnit.Kilometer,
        LatLng(centerLat, centerLng),
        LatLng(getLat(a), getLng(a)),
      );
      final distB = distanceCalculator.as(
        LengthUnit.Kilometer,
        LatLng(centerLat, centerLng),
        LatLng(getLat(b), getLng(b)),
      );
      return distA.compareTo(distB);
    });

    return filtered;
  }

  /// Calcule la distance en kilomètres entre deux points.
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    final distance = const Distance();
    return distance.as(
      LengthUnit.Kilometer,
      LatLng(lat1, lng1),
      LatLng(lat2, lng2),
    );
  }

  /// Calcule la distance en kilomètres entre deux points (alias).
  double calculateDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    return calculateDistance(lat1, lng1, lat2, lng2);
  }
}
