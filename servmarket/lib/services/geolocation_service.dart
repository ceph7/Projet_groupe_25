import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

/// Service de géolocalisation.
/// Gère la récupération de la position, les permissions et le géocodage.
class GeolocationService {
  GeolocationService._();
  static final GeolocationService instance = GeolocationService._();

  /// Vérifie si les permissions de localisation sont accordées.
  Future<bool> hasPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
             permission == LocationPermission.whileInUse;
    } catch (e) {
      // Ignore errors in production
      return false;
    }
  }

  /// Demande la permission de localisation.
  Future<LocationPermission> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Les services de localisation sont désactivés
        return LocationPermission.denied;
      }

      return await Geolocator.requestPermission();
    } catch (e) {
      // Ignore errors in production
      return LocationPermission.denied;
    }
  }

  /// Récupère la position actuelle de l'utilisateur.
  /// La position n'est pas persistée, utilisée uniquement localement.
  /// Retourne null si la permission est refusée ou si les services sont désactivés.
  Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await this.hasPermission();
      if (!hasPermission) {
        LocationPermission permission = await requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      // Vérifier à nouveau que les services sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // Ignore errors in production
      return null;
    }
  }

  /// Géocode une adresse en coordonnées GPS.
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;
      
      final location = locations.first;
      return LatLng(location.latitude, location.longitude);
    } catch (e) {
      throw Exception('Erreur lors du géocodage: $e');
    }
  }

  /// Géocode inverse: coordonnées → adresse.
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      
      final placemark = placemarks.first;
      final street = placemark.street;
      final locality = placemark.locality;
      final country = placemark.country;
      
      return '$street, $locality, $country'.replaceAll(', null', '').trim();
    } catch (e) {
      throw Exception('Erreur lors du géocodage inverse: $e');
    }
  }

  /// Calcule la distance en mètres entre deux points (formule Haversine).
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    final Distance distance = const Distance();
    return distance.as(LengthUnit.Meter, LatLng(lat1, lng1), LatLng(lat2, lng2));
  }

  /// Calcule la distance en kilomètres entre deux points.
  double calculateDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    return calculateDistance(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Génère un géohash à partir de coordonnées GPS (implémentation simple).
  String getGeohash(double lat, double lng, {int precision = 9}) {
    const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    int idx = 0;
    int bit = 0;
    int evenBit = 1;
    String geohash = '';
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    
    while (geohash.length < precision) {
      if (evenBit == 1) {
        double lonMid = (lonMin + lonMax) / 2;
        if (lng > lonMid) {
          idx = (idx << 1) + 1;
          lonMin = lonMid;
        } else {
          idx = idx << 1;
          lonMax = lonMid;
        }
      } else {
        double latMid = (latMin + latMax) / 2;
        if (lat > latMid) {
          idx = (idx << 1) + 1;
          latMin = latMid;
        } else {
          idx = idx << 1;
          latMax = latMid;
        }
      }
      evenBit = evenBit == 1 ? 0 : 1;
      bit++;
      if (bit == 5) {
        geohash += base32[idx];
        bit = 0;
        idx = 0;
      }
    }
    return geohash;
  }

  /// Alias pour reverseGeocode pour compatibilité.
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    return reverseGeocode(lat, lng);
  }
}
