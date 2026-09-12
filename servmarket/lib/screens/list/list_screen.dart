import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/provider_profile.dart';
import '../../providers/search_provider.dart';
import '../../services/geohash_service.dart';
import '../../widgets/location_permission_dialog.dart';
import '../provider_detail/provider_detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final GeohashService _geohashService = GeohashService.instance;
  final _addressController = TextEditingController();
  bool _locationPermissionAsked = false;
  bool _dialogShown = false;
  bool _isInitialized = false;

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
    setState(() => _locationPermissionAsked = true);
    
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

  Future<void> _searchByAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    
    final searchProvider = context.read<SearchProvider>();
    await searchProvider.searchByAddress(address);
  }

  void _onCategoryTap(String category) {
    final searchProvider = context.read<SearchProvider>();
    searchProvider.setCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        // Show permission dialog on first load if not asked yet
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
            title: const Text('Prestataires'),
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
              IconButton(
                icon: Icon(searchProvider.isManualSearch ? Icons.list_rounded : Icons.search_rounded),
                onPressed: () {
                  searchProvider.toggleManualSearch(!searchProvider.isManualSearch);
                  if (!searchProvider.isManualSearch) {
                    _addressController.clear();
                  }
                },
                tooltip: searchProvider.isManualSearch ? 'Liste' : 'Recherche par adresse',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar (manual search mode)
              if (searchProvider.isManualSearch) _buildAddressSearch(searchProvider),
              // Radius slider (location mode)
              if (searchProvider.useLocation && !searchProvider.isManualSearch) _buildRadiusSlider(searchProvider),
              // Filtre par catégorie
              _buildCategoryFilter(searchProvider),
              const Divider(height: 1),
              // Liste des prestataires
              Expanded(
                child: _buildProviderList(searchProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressSearch(SearchProvider searchProvider) {
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

  Widget _buildRadiusSlider(SearchProvider searchProvider) {
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
                '${searchProvider.searchRadiusKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: searchProvider.searchRadiusKm,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            activeColor: AppTheme.accentColor,
            onChanged: (value) {
              searchProvider.setSearchRadius(value);
            },
          ),
        ],
      ),
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

  Widget _buildProviderList(SearchProvider searchProvider) {
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

    if (searchProvider.providers.isEmpty) {
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
                searchProvider.selectedCategory != null
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
      itemCount: searchProvider.providers.length,
      itemBuilder: (context, index) {
        final provider = searchProvider.providers[index];
        return _ProviderCard(
          provider: provider,
          distance: searchProvider.currentPosition != null && provider.lat != null && provider.lng != null
              ? _geohashService.calculateDistanceKm(searchProvider.currentPosition!.latitude, searchProvider.currentPosition!.longitude, provider.lat!, provider.lng!)
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
