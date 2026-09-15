import 'package:flutter/material.dart';
import '../../models/provider_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/geohash_helper.dart';
import '../../widgets/provider_card.dart';
import '../provider_detail/provider_detail_screen.dart';
import '../provider_form/provider_form_screen.dart';
import '../profile/profile_screen.dart';

/// Écran d'accueil : recherche et liste des prestataires proches.
/// Couvre les issues #14 (rayon modifiable + état vide), #15 (recherche
/// manuelle par ville/adresse), #16 (positions simulées démo), #17 (liste
/// des résultats), #19 (filtres par catégorie), #20 (cohérence liste/carte
/// après changement de filtre ou rayon).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();
  final _authService = AuthService();

  double? _latitude;
  double? _longitude;
  double _radiusKm = 10;
  String? _selectedCategory;

  bool _isLoading = true;
  String? _statusMessage;
  List<ProviderModel> _results = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  /// Issue #11/#12 : tente la géolocalisation réelle au démarrage.
  Future<void> _initLocation() async {
    setState(() => _isLoading = true);
    final result = await _locationService.getCurrentPosition();

    if (result.status == LocationStatus.granted) {
      _latitude = result.latitude;
      _longitude = result.longitude;
      await _search();
    } else {
      // Issue #15 : mode de repli si la permission est refusée/indisponible.
      setState(() {
        _isLoading = false;
        _statusMessage =
            'Position indisponible. Utilisez la recherche manuelle ci-dessous.';
      });
    }
  }

  /// Issue #16 : permet de forcer une position simulée fiable pour la démo.
  void _useDemoPosition(String label) {
    final pos = LocationService.demoPositions[label]!;
    setState(() {
      _latitude = pos['lat'];
      _longitude = pos['lng'];
    });
    _search();
  }

  Future<void> _search() async {
    if (_latitude == null || _longitude == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final results = await _firestoreService.searchNearby(
      latitude: _latitude!,
      longitude: _longitude!,
      radiusInKm: _radiusKm,
      category: _selectedCategory,
    );

    setState(() {
      _results = results;
      _isLoading = false;
      // Issue #14 : état vide explicite si aucun résultat.
      _statusMessage = results.isEmpty
          ? 'Aucun prestataire trouvé dans un rayon de ${_radiusKm.toInt()} km.'
          : null;
    });
  }

  double? _distanceTo(ProviderModel p) {
    if (_latitude == null || _longitude == null) return null;
    return GeohashHelper.distanceInKm(_latitude!, _longitude!, p.lat, p.lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ServMarket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProviderFormScreen()),
        ),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Ma fiche'),
      ),
      body: RefreshIndicator(
        onRefresh: _search,
        color: AppColors.primary,
        child: Column(
          children: [
            _buildFiltersBar(),
            Expanded(child: _buildResultsArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Issue #19 : filtres par catégorie.
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'Toutes',
                  selected: _selectedCategory == null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    _search();
                  },
                ),
                ...ServiceCategories.all.map((cat) => _CategoryChip(
                      label: cat,
                      selected: _selectedCategory == cat,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        _search(); // issue #20 : recherche relancée à chaque changement
                      },
                    )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Issue #14 : rayon de recherche modifiable.
          Row(
            children: [
              Icon(Icons.radar_rounded, size: 18, color: AppColors.textGrey),
              const SizedBox(width: 6),
              Text('Rayon : ${_radiusKm.toInt()} km', style: AppTextStyles.caption),
              Expanded(
                child: Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _radiusKm = v),
                  onChangeEnd: (_) => _search(), // issue #20
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_latitude == null) {
      // Issue #15 : recherche manuelle par ville/adresse.
      return _buildManualLocationPrompt();
    }

    if (_statusMessage != null && _results.isEmpty) {
      return _buildEmptyState(_statusMessage!);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final provider = _results[index];
        return ProviderCard(
          provider: provider,
          distanceKm: _distanceTo(provider),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProviderDetailScreen(providerId: provider.id!)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: AppColors.textGrey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.body.copyWith(color: AppColors.textGrey), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => setState(() => _radiusKm = 50),
              child: const Text('Élargir le rayon à 50 km'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualLocationPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded, size: 56, color: AppColors.textGrey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              _statusMessage ?? 'Position non disponible.',
              style: AppTextStyles.body.copyWith(color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initLocation,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Réessayer la géolocalisation'),
            ),
            const SizedBox(height: 12),
            Text('— ou utilisez une position de démo —', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: LocationService.demoPositions.keys
                  .map((label) => ActionChip(
                        label: Text(label),
                        onPressed: () => _useDemoPosition(label),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.background,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        ),
      ),
    );
  }
}