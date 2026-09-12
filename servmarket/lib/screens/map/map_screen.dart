import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/provider_profile.dart';
import '../../providers/search_provider.dart';
import '../provider_detail/provider_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Initialisation différée pour attendre que SearchProvider soit prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchProvider = context.read<SearchProvider>();
      searchProvider.loadProviders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Carte'),
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
          ),
          body: _buildMap(searchProvider),
        );
      },
    );
  }

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

    if (searchProvider.providers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun prestataire sur la carte',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Filter providers with valid coordinates
    final validProviders = searchProvider.providers
        .where((p) => p.lat != null && p.lng != null)
        .toList();

    if (validProviders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun prestataire avec des coordonnées',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          validProviders.first.lat!,
          validProviders.first.lng!,
        ),
        initialZoom: 13.0,
        minZoom: 4.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.groupe25.servmarket',
        ),
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
      ],
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