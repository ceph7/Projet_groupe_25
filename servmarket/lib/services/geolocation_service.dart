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
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Demande la permission de localisation.
  Future<LocationPermission> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    return await Geolocator.requestPermission();
  }

  /// Récupère la position actuelle de l'utilisateur.
  /// La position n'est pas persistée, utilisée uniquement localement.
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

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la position: $e');
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
}
