import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';
import '../../models/provider_profile.dart';
import '../../repositories/provider_repository.dart';
import '../provider_detail/provider_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ProviderRepository _repository = ProviderRepository.instance;
  List<ProviderProfile> _providers = [];
  bool _isLoading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final providers = await _repository.getPublished();
      if (mounted) {
        setState(() {
          _providers = providers;
          _isLoading = false;
        });
        
        // Center map on first provider if available
        if (providers.isNotEmpty && 
            providers.first.lat != null && 
            providers.first.lng != null) {
          _mapController.move(
            LatLng(providers.first.lat!, providers.first.lng!),
            13.0,
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _buildMap(),
    );
  }

  Widget _buildMap() {
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
    final validProviders = _providers
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