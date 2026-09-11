import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../models/provider_profile.dart';
import '../../repositories/provider_repository.dart';
import '../../services/geolocation_service.dart';
import '../../services/geohash_service.dart';
import '../../widgets/location_permission_dialog.dart';
import '../provider_detail/provider_detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ProviderRepository _repository = ProviderRepository.instance;
  final GeolocationService _geoService = GeolocationService.instance;
  final GeohashService _geohashService = GeohashService.instance;
  
  List<ProviderProfile> _providers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedCategory;
  
  // Geolocation
  Position? _currentPosition;
  bool _locationPermissionAsked = false;
  bool _useLocation = false;
  double _searchRadiusKm = 5.0; // Default 5km
  
  // Manual search
  final _addressController = TextEditingController();
  bool _isManualSearch = false;

  final List<String> _categories = [
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

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final hasPermission = await _geoService.hasPermission();
    if (hasPermission) {
      _useLocation = true;
      _loadProvidersWithLocation();
    } else {
      _loadProviders();
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _locationPermissionAsked = true);
    
    final permission = await _geoService.requestPermission();
    if (permission == LocationPermission.always || 
        permission == LocationPermission.whileInUse) {
      setState(() => _useLocation = true);
      _loadProvidersWithLocation();
    } else {
      setState(() => _useLocation = false);
      _loadProviders();
    }
  }

  Future<void> _loadProvidersWithLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _geoService.getCurrentPosition();
      if (position == null) {
        _loadProviders();
        return;
      }

      setState(() => _currentPosition = position);

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

      if (mounted) {
        setState(() {
          _providers = filteredProviders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<ProviderProfile> providers;
      if (_selectedCategory == null || _selectedCategory == 'Toutes') {
        providers = await _repository.getPublished();
      } else {
        providers = await _repository.getByCategory(_selectedCategory!);
      }
      
      if (mounted) {
        setState(() {
          _providers = providers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchByAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final coords = await _geoService.geocodeAddress(address);
      if (coords == null) {
        setState(() {
          _errorMessage = 'Adresse non trouvée';
          _isLoading = false;
        });
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

      if (mounted) {
        setState(() {
          _providers = filteredProviders;
          _isManualSearch = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _onCategoryTap(String category) {
    setState(() {
      _selectedCategory = category == 'Toutes' ? null : category;
    });
    if (_useLocation && _currentPosition != null) {
      _loadProvidersWithLocation();
    } else {
      _loadProviders();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show permission dialog on first load if not asked yet
    if (!_locationPermissionAsked && !_useLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => LocationPermissionDialog(
            onAllow: () {
              Navigator.of(context).pop();
              _requestLocationPermission();
            },
            onDeny: () {
              Navigator.of(context).pop();
              _loadProviders();
            },
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestataires'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          if (_useLocation)
            IconButton(
              icon: const Icon(Icons.my_location_rounded),
              onPressed: _loadProvidersWithLocation,
              tooltip: 'Ma position',
            ),
          IconButton(
            icon: Icon(_isManualSearch ? Icons.list_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() => _isManualSearch = !_isManualSearch);
              if (!_isManualSearch) {
                _addressController.clear();
                if (_useLocation && _currentPosition != null) {
                  _loadProvidersWithLocation();
                } else {
                  _loadProviders();
                }
              }
            },
            tooltip: _isManualSearch ? 'Liste' : 'Recherche par adresse',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (manual search mode)
          if (_isManualSearch) _buildAddressSearch(),
          // Radius slider (location mode)
          if (_useLocation && !_isManualSearch) _buildRadiusSlider(),
          // Filtre par catégorie
          _buildCategoryFilter(),
          const Divider(height: 1),
          // Liste des prestataires
          Expanded(
            child: _buildProviderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSearch() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Entrez une ville ou adresse',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _addressController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _addressController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _searchByAddress(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _searchByAddress,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rayon de recherche',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_searchRadiusKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _searchRadiusKm,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            activeColor: AppTheme.accentColor,
            onChanged: (value) {
              setState(() => _searchRadiusKm = value);
            },
            onChangeEnd: (_) {
              if (_currentPosition != null) {
                _loadProvidersWithLocation();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == null
              ? category == 'Toutes'
              : category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _onCategoryTap(category),
              selectedColor: AppTheme.accentColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.accentColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.accentColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.accentColor : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProviders,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_providers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun prestataire trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategory != null
                    ? 'Essayez une autre catégorie'
                    : 'Revenez plus tard',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return _ProviderCard(
          provider: provider,
          distance: _currentPosition != null && provider.lat != null && provider.lng != null
              ? _geohashService.calculateDistanceKm(_currentPosition!.latitude, _currentPosition!.longitude, provider.lat!, provider.lng!)
              : null,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProviderDetailScreen(provider: provider),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderProfile provider;
  final double? distance;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: AppTheme.accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (provider.category != null)
                      Text(
                        provider.category!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (provider.address != null)
                      Text(
                        provider.address!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Distance (affichée si localisation activée)
              if (distance != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance!.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}