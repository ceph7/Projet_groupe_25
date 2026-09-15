import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/provider_profile.dart';
import '../repositories/provider_repository.dart';
import '../services/geolocation_service.dart';
import '../services/geohash_service.dart';

/// Provider pour l'état de recherche partagé entre ListScreen et MapScreen.
/// Assure la synchronisation des filtres et résultats entre les deux vues.
class SearchProvider extends ChangeNotifier {
  SearchProvider._();
  static final SearchProvider instance = SearchProvider._();

  final ProviderRepository _repository = ProviderRepository.instance;
  final GeolocationService geoService = GeolocationService.instance;
  final GeohashService _geohashService = GeohashService.instance;

  // État de recherche
  List<ProviderProfile> _providers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;
  
  // Géolocalisation
  Position? _currentPosition;
  bool _useLocation = false;
  double _searchRadiusKm = 5.0;
  
  // Recherche manuelle
  String _searchAddress = '';
  bool _isManualSearch = false;

  // Getters
  List<ProviderProfile> get providers => _providers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  Position? get currentPosition => _currentPosition;
  bool get useLocation => _useLocation;
  double get searchRadiusKm => _searchRadiusKm;
  String get searchAddress => _searchAddress;
  bool get isManualSearch => _isManualSearch;

  final List<String> categories = [
    'Toutes',
    'Plomberie',
    'Électricité',
    'Menuiserie',
    'Peinture',
    'Jardinage',
    'Nettoyage',
    'Coiffure',
    'Réparation',
    'Autre',
  ];

  /// Initialise la recherche avec ou sans localisation
  Future<void> initialize({bool useLocation = false}) async {
    _useLocation = useLocation;
    if (useLocation) {
      final hasPermission = await geoService.hasPermission();
      if (hasPermission) {
        await loadWithLocation();
      } else {
        await loadProviders();
      }
    } else {
      await loadProviders();
    }
  }

  /// Charge les prestataires avec localisation GPS
  Future<void> loadWithLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await geoService.getCurrentPosition();
      if (position == null) {
        await loadProviders();
        return;
      }

      _currentPosition = position;

      final bounds = _geohashService.calculateBounds(
        position.latitude,
        position.longitude,
        _searchRadiusKm,
      );

      List<ProviderProfile> providers;
      if (_selectedCategory == null || _selectedCategory == 'Toutes') {
        providers = await _repository.searchByBounds(
          minLat: double.parse(bounds['minLat']!),
          maxLat: double.parse(bounds['maxLat']!),
          minLng: double.parse(bounds['minLng']!),
          maxLng: double.parse(bounds['maxLng']!),
        );
      } else {
        providers = await _repository.searchByBounds(
          minLat: double.parse(bounds['minLat']!),
          maxLat: double.parse(bounds['maxLat']!),
          minLng: double.parse(bounds['minLng']!),
          maxLng: double.parse(bounds['maxLng']!),
          category: _selectedCategory,
        );
      }

      // Filtrer par distance réelle (Haversine)
      final filteredProviders = _geohashService.filterByDistance(
        providers,
        position.latitude,
        position.longitude,
        _searchRadiusKm,
        (provider) => provider.lat ?? 0,
        (provider) => provider.lng ?? 0,
      );

      _providers = filteredProviders;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les prestataires sans localisation
  Future<void> loadProviders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<ProviderProfile> providers;
      if (_selectedCategory == null || _selectedCategory == 'Toutes') {
        providers = await _repository.getPublished();
      } else {
        providers = await _repository.getByCategory(_selectedCategory!);
      }
      
      _providers = providers;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recherche par adresse manuelle (geocoding)
  Future<void> searchByAddress(String address) async {
    if (address.trim().isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    _searchAddress = address;
    _isManualSearch = true;
    notifyListeners();

    try {
      final coords = await geoService.geocodeAddress(address);
      if (coords == null) {
        _errorMessage = 'Adresse non trouvée';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final bounds = _geohashService.calculateBounds(
        coords.latitude,
        coords.longitude,
        _searchRadiusKm,
      );

      List<ProviderProfile> providers;
      if (_selectedCategory == null || _selectedCategory == 'Toutes') {
        providers = await _repository.searchByBounds(
          minLat: double.parse(bounds['minLat']!),
          maxLat: double.parse(bounds['maxLat']!),
          minLng: double.parse(bounds['minLng']!),
          maxLng: double.parse(bounds['maxLng']!),
        );
      } else {
        providers = await _repository.searchByBounds(
          minLat: double.parse(bounds['minLat']!),
          maxLat: double.parse(bounds['maxLat']!),
          minLng: double.parse(bounds['minLng']!),
          maxLng: double.parse(bounds['maxLng']!),
          category: _selectedCategory,
        );
      }

      final filteredProviders = _geohashService.filterByDistance(
        providers,
        coords.latitude,
        coords.longitude,
        _searchRadiusKm,
        (provider) => provider.lat ?? 0,
        (provider) => provider.lng ?? 0,
      );

      _providers = filteredProviders;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change la catégorie sélectionnée et recharge les données
  void setCategory(String category) {
    _selectedCategory = category == 'Toutes' ? null : category;
    
    if (_useLocation && _currentPosition != null) {
      loadWithLocation();
    } else if (_isManualSearch && _searchAddress.isNotEmpty) {
      searchByAddress(_searchAddress);
    } else {
      loadProviders();
    }
  }

  /// Change le rayon de recherche et recharge les données
  void setSearchRadius(double radius) {
    _searchRadiusKm = radius;
    
    if (_useLocation && _currentPosition != null) {
      loadWithLocation();
    } else if (_isManualSearch && _searchAddress.isNotEmpty) {
      searchByAddress(_searchAddress);
    }
  }

  /// Active/désactive le mode recherche manuelle
  void toggleManualSearch(bool enabled) {
    _isManualSearch = enabled;
    if (!enabled) {
      _searchAddress = '';
      if (_useLocation && _currentPosition != null) {
        loadWithLocation();
      } else {
        loadProviders();
      }
    }
    notifyListeners();
  }

  /// Réinitialise tous les filtres
  void resetFilters() {
    _selectedCategory = null;
    _searchAddress = '';
    _isManualSearch = false;
    _searchRadiusKm = 5.0;
    
    if (_useLocation && _currentPosition != null) {
      loadWithLocation();
    } else {
      loadProviders();
    }
  }

  /// Met à jour la position actuelle
  void updatePosition(Position position) {
    _currentPosition = position;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
