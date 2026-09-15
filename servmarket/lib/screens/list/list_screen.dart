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
            backgroundColor: AppTheme.backgroundColor,
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
              const Divider(height: 1, color: AppTheme.borderSubtle),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        return Container(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          color: AppTheme.surfaceMuted,
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
                    fillColor: AppTheme.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 20 : 16,
                    ),
                  ),
                  onSubmitted: (_) => _searchByAddress(),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              ElevatedButton(
                onPressed: _searchByAddress,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 20,
                    vertical: isTablet ? 20 : 16,
                  ),
                ),
                child: const Icon(Icons.search_rounded),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadiusSlider(SearchProvider searchProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surfaceMuted,
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
                  color: AppTheme.textPrimary,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        return Container(
          height: isTablet ? 70 : 60,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 12 : 8,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: searchProvider.categories.length,
            itemBuilder: (context, index) {
              final category = searchProvider.categories[index];
              final isSelected = searchProvider.selectedCategory == null
                  ? category == 'Toutes'
                  : category == searchProvider.selectedCategory;

              return Padding(
                padding: EdgeInsets.only(right: isTablet ? 12 : 8),
                child: FilterChip(
                  label: Text(
                    category,
                    style: TextStyle(fontSize: isTablet ? 15 : 14),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _onCategoryTap(category),
                  selectedColor: AppTheme.accentColor.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.accentColor,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: isTablet ? 15 : 14,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.accentColor : AppTheme.borderSubtle,
                    width: isTablet ? 1.5 : 1,
                  ),
                  backgroundColor: AppTheme.surfaceColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: isTablet ? 12 : 8,
                  ),
                ),
              );
            },
          ),
        );
      },
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
              const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucun prestataire trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                searchProvider.selectedCategory != null
                    ? 'Essayez une autre catégorie'
                    : 'Revenez plus tard',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final crossAxisCount = isTablet ? 2 : 1;

        if (isTablet) {
          return GridView.builder(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
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

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: searchProvider.providers.length,
          separatorBuilder: (context, index) => const Divider(
            color: AppTheme.borderSubtle,
            height: 1,
          ),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Colored dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.categoryColor(provider.category ?? 'Autre'),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${provider.category ?? 'Autre'}${distance != null ? ' — ${distance!.toStringAsFixed(1)} km' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_outward_rounded,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
