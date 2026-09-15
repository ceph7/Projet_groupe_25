import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Résultat enrichi d'une tentative de géolocalisation, pour piloter l'UI
/// (permission refusée, service désactivé, succès...).
enum LocationStatus { granted, denied, deniedForever, serviceDisabled }

class LocationResult {
  final LocationStatus status;
  final double? latitude;
  final double? longitude;

  LocationResult({required this.status, this.latitude, this.longitude});
}

/// Service centralisant la géolocalisation.
/// Couvre les issues #11 (permission + explication), #12 (position locale non
/// persistée), #15 (recherche manuelle par ville/adresse), #16 (positions
/// simulées pour la démo).
class LocationService {
  /// Issue #11 + #12 : demande la permission puis récupère la position actuelle.
  /// La position n'est JAMAIS persistée en base (issue #12) : elle est
  /// utilisée localement le temps de la requête puis jetée.
  Future<LocationResult> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(status: LocationStatus.serviceDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult(status: LocationStatus.denied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult(status: LocationStatus.deniedForever);
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LocationResult(
      status: LocationStatus.granted,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Issue #15 : Recherche manuelle par ville/adresse (mode de repli si la
  /// géolocalisation est refusée ou indisponible).
  Future<LocationResult> getPositionFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        return LocationResult(status: LocationStatus.denied);
      }
      return LocationResult(
        status: LocationStatus.granted,
        latitude: locations.first.latitude,
        longitude: locations.first.longitude,
      );
    } catch (_) {
      return LocationResult(status: LocationStatus.denied);
    }
  }

  /// Issue #16 : Positions simulées pour la démo — jeu de coordonnées fixes
  /// (Lomé, Togo) à utiliser en secours si le GPS/réseau échoue en direct.
  static const Map<String, Map<String, double>> demoPositions = {
    'Lomé Centre': {'lat': 6.1319, 'lng': 1.2228},
    'Agoè': {'lat': 6.1875, 'lng': 1.2146},
    'Bè': {'lat': 6.1234, 'lng': 1.2456},
    'Tokoin': {'lat': 6.1503, 'lng': 1.2154},
  };
}