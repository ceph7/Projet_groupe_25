import 'package:flutter/material.dart';
import '../../models/provider_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/geohash_helper.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/message_banner.dart';

/// Écran de création/édition de fiche prestataire.
/// Couvre l'issue #8 (création/modification — propriétaire uniquement),
/// #9 (activer/désactiver la fiche), #21 (responsive téléphone/tablette
/// via LayoutBuilder), #26 (validation du numéro de téléphone).
class ProviderFormScreen extends StatefulWidget {
  final ProviderModel? existingProvider;

  const ProviderFormScreen({super.key, this.existingProvider});

  @override
  State<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _ProviderFormScreenState extends State<ProviderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _locationService = LocationService();
  final _authService = AuthService();

  String _selectedCategory = ServiceCategories.all.first;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  String? _errorMessage;
  double? _lat;
  double? _lng;

  bool get _isEditing => widget.existingProvider != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.existingProvider!;
      _nameController.text = p.name;
      _descriptionController.text = p.description;
      _phoneController.text = p.phone;
      _selectedCategory = p.category;
      _lat = p.lat;
      _lng = p.lng;
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isFetchingLocation = true);
    final result = await _locationService.getCurrentPosition();
    setState(() {
      _isFetchingLocation = false;
      if (result.status == LocationStatus.granted) {
        _lat = result.latitude;
        _lng = result.longitude;
      } else {
        _errorMessage = 'Impossible de récupérer votre position. Réessayez.';
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      setState(() => _errorMessage = 'Veuillez capturer votre position avant de continuer.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uid = _authService.currentUser!.uid;
      final geohash = GeohashHelper.encode(_lat!, _lng!);

      final provider = ProviderModel(
        id: widget.existingProvider?.id,
        ownerId: uid,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        phone: Validators.normalizePhone(_phoneController.text),
        lat: _lat!,
        lng: _lng!,
        geohash: geohash,
        isActive: widget.existingProvider?.isActive ?? true,
      );

      if (_isEditing) {
        await _firestoreService.updateProvider(provider);
      } else {
        await _firestoreService.createProvider(provider);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _errorMessage = 'Une erreur est survenue lors de l\'enregistrement.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Issue #9 : activer/désactiver la visibilité publique de la fiche.
  Future<void> _toggleActive() async {
    if (widget.existingProvider?.id == null) return;
    final newState = !(widget.existingProvider!.isActive);
    if (newState) {
      await _firestoreService.reactivateProvider(widget.existingProvider!.id!);
    } else {
      await _firestoreService.deactivateProvider(widget.existingProvider!.id!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newState ? 'Fiche réactivée.' : 'Fiche désactivée.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier ma fiche' : 'Créer ma fiche'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(
                widget.existingProvider!.isActive
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              tooltip: 'Activer / désactiver la fiche',
              onPressed: _toggleActive,
            ),
        ],
      ),
      // Issue #21 : responsive — largeur du formulaire bornée sur tablette.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 600 ? 520.0 : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) MessageBanner(message: _errorMessage!),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom / Entreprise',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => Validators.required(v, label: 'Le nom'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie de service',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: ServiceCategories.all
                              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '+228 90 00 00 00',
                          ),
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description (optionnel)',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLocationCapture(),
                        const SizedBox(height: 28),
                        PrimaryButton(
                          label: _isEditing ? 'Enregistrer les modifications' : 'Publier ma fiche',
                          onPressed: _handleSubmit,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationCapture() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            _lat != null ? Icons.check_circle_rounded : Icons.location_on_outlined,
            color: _lat != null ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _lat != null
                  ? 'Position capturée avec succès.'
                  : 'Position requise pour être trouvé sur la carte.',
              style: AppTextStyles.caption,
            ),
          ),
          TextButton(
            onPressed: _isFetchingLocation ? null : _captureLocation,
            child: _isFetchingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_lat != null ? 'Actualiser' : 'Capturer'),
          ),
        ],
      ),
    );
  }
}