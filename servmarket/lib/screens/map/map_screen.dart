import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/provider_profile.dart';
import '../../providers/search_provider.dart';
import '../../widgets/location_permission_dialog.dart';
import '../provider_detail/provider_detail_screen.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _locationPermissionAsked = false;
  bool _dialogShown = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final searchProvider = context.read<SearchProvider>();
    final geoService = searchProvider.geoService;
    final hasPermission = await geoService.hasPermission();
    if (hasPermission) {
      await searchProvider.initialize(useLocation: true);
    } else {
      await searchProvider.initialize(useLocation: false);
    }
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _locationPermissionAsked = true;
    });
    
    final searchProvider = context.read<SearchProvider>();
    final geoService = searchProvider.geoService;
    final permission = await geoService.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await searchProvider.initialize(useLocation: true);
    } else {
      await searchProvider.initialize(useLocation: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        // Show permission dialog on first load if not asked yet and not shown yet
        if (!_dialogShown && !_locationPermissionAsked && !searchProvider.useLocation && _isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_dialogShown && !_locationPermissionAsked && !searchProvider.useLocation) {
              setState(() => _dialogShown = true);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => LocationPermissionDialog(
                  onAllow: () {
                    Navigator.of(context).pop();
                    _requestLocationPermission();
                  },
                  onDeny: () {
                    Navigator.of(context).pop();
                    searchProvider.initialize(useLocation: false);
                  },
                ),
              );
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Carte'),
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
            actions: [
              if (searchProvider.useLocation)
                IconButton(
                  icon: const Icon(Icons.my_location_rounded),
                  onPressed: () => searchProvider.loadWithLocation(),
                  tooltip: 'Ma position',
                ),
            ],
          ),
          body: Column(
            children: [
              // Filtre par catégorie
              _buildCategoryFilter(searchProvider),
              const Divider(height: 1),
              // Carte
              Expanded(
                child: _buildMap(searchProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter(SearchProvider searchProvider) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: searchProvider.categories.length,
        itemBuilder: (context, index) {
          final category = searchProvider.categories[index];
          final isSelected = searchProvider.selectedCategory == null
              ? category == 'Toutes'
              : category == searchProvider.selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                searchProvider.setCategory(category);
              },
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

  // Centre par défaut (France métropolitaine) si pas de prestataires avec coordonnées
  static const LatLng _defaultCenter = LatLng(46.603354, 1.888334);

  Widget _buildMap(SearchProvider searchProvider) {
    if (searchProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchProvider.errorMessage != null) {
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
                searchProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => searchProvider.loadProviders(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter providers with valid coordinates
    final validProviders = searchProvider.providers
        .where((p) => p.lat != null && p.lng != null)
        .toList();

    // Déterminer le centre initial de la carte
    LatLng initialCenter;
    if (validProviders.isNotEmpty) {
      initialCenter = LatLng(validProviders.first.lat!, validProviders.first.lng!);
    } else if (searchProvider.currentPosition != null) {
      initialCenter = LatLng(searchProvider.currentPosition!.latitude, searchProvider.currentPosition!.longitude);
    } else {
      initialCenter = _defaultCenter;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: validProviders.isNotEmpty || searchProvider.currentPosition != null ? 13.0 : 6.0,
        minZoom: 4.0,
        maxZoom: 18.0,
        onMapReady: () {
          // Optionnel: fit bounds si on a des prestataires
          if (validProviders.length > 1) {
            _fitBounds(validProviders);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.groupe25.servmarket',
          // Ajouter des options pour améliorer le chargement des tuiles
          maxZoom: 18,
          tileProvider: NetworkTileProvider(),
        ),
        if (validProviders.isNotEmpty)
          MarkerLayer(
            markers: validProviders.map((provider) {
              return Marker(
                point: LatLng(provider.lat!, provider.lng!),
                width: 40,
                height: 40,
                child: _MarkerWidget(
                  provider: provider,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProviderDetailScreen(provider: provider),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        // Afficher la position actuelle de l'utilisateur si disponible
        if (searchProvider.currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(searchProvider.currentPosition!.latitude, searchProvider.currentPosition!.longitude),
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        // Message d'information si aucun prestataire avec coordonnées
        if (validProviders.isEmpty && searchProvider.providers.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    size: 32,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${searchProvider.providers.length} prestataire(s) trouvé(s) mais sans coordonnées GPS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Les prestataires doivent activer la détection GPS dans leur profil pour apparaître sur la carte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _fitBounds(List<ProviderProfile> providers) {
    if (providers.isEmpty) return;
    
    double minLat = providers.first.lat!;
    double maxLat = providers.first.lat!;
    double minLng = providers.first.lng!;
    double maxLng = providers.first.lng!;
    
    for (final provider in providers) {
      if (provider.lat != null && provider.lng != null) {
        minLat = math.min(minLat, provider.lat!);
        maxLat = math.max(maxLat, provider.lat!);
        minLng = math.min(minLng, provider.lng!);
        maxLng = math.max(maxLng, provider.lng!);
      }
    }
    
    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
    
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }
}

class _MarkerWidget extends StatelessWidget {
  final ProviderProfile provider;
  final VoidCallback onTap;

  const _MarkerWidget({
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.business_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
