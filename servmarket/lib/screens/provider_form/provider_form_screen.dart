import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/provider_profile.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/provider_repository.dart';
import '../../services/geolocation_service.dart';
import '../../services/storage_service.dart';

class ProviderFormScreen extends StatefulWidget {
  final ProviderProfile? existingProfile;

  const ProviderFormScreen({super.key, this.existingProfile});

  @override
  State<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _ProviderFormScreenState extends State<ProviderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _categoryController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isPublished = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _photoUrl;
  File? _localPhotoFile;
  double? _lat;
  double? _lng;
  String? _geohash;

  final List<String> _categories = [
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

  /// Normalise un numéro de téléphone international
  String _normalizePhoneNumber(String phone) {
    // Supprime tous les caractères non numériques sauf le + au début
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Si commence par +, garde le format international
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    
    // Sinon, ajoute le + pour format international
    return '+$cleaned';
  }

  /// Valide un numéro de téléphone international
  bool _isValidPhoneNumber(String phone) {
    // Supprime tous les caractères non numériques sauf le +
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Doit commencer par + et contenir entre 8 et 15 chiffres (standard international)
    final regex = RegExp(r'^\+[1-9][0-9]{7,14}$');
    return regex.hasMatch(cleaned);
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _loadExistingProfile(widget.existingProfile!);
    }
  }

  void _loadExistingProfile(ProviderProfile profile) {
    _nameController.text = profile.name;
    _descriptionController.text = profile.description ?? '';
    _phoneController.text = profile.phone ?? '';
    _emailController.text = profile.email ?? '';
    _categoryController.text = profile.category ?? '';
    _addressController.text = profile.address ?? '';
    _isPublished = profile.isPublished;
    _photoUrl = profile.photoUrl;
    _localPhotoFile = null;
    _lat = profile.lat;
    _lng = profile.lng;
    _geohash = profile.geohash;
  }

  Future<void> _detectLocation() async {
    try {
      setState(() => _isLoading = true);

      final geoService = GeolocationService.instance;

      // Vérifier et demander la permission via le service
      final hasPermission = await geoService.hasPermission();
      if (!hasPermission) {
        final permission = await geoService.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission de localisation refusée')),
            );
          }
          return;
        }
      }

      final position = await geoService.getCurrentPosition();

      if (position == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'obtenir la position')),
          );
        }
        return;
      }

      final address = await geoService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final geohash = geoService.getGeohash(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _addressController.text = address ?? '';
          _lat = position.latitude;
          _lng = position.longitude;
          _geohash = geohash;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de localisation: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          _localPhotoFile = File(image.path);
          _photoUrl = null; // Réinitialiser l'URL si on sélectionne une nouvelle photo locale
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _categoryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      setState(() => _errorMessage = 'Vous devez être connecté pour créer un profil');
      return;
    }

    if (auth.user!.role != UserRole.provider) {
      setState(() => _errorMessage = 'Seuls les prestataires peuvent créer un profil');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ProviderRepository.instance;
      final storageService = StorageService.instance;

      // Upload de la photo si une nouvelle photo locale est sélectionnée
      String? finalPhotoUrl = _photoUrl;
      if (_localPhotoFile != null) {
        try {
          final providerId = widget.existingProfile?.id ?? auth.user!.uid;
          finalPhotoUrl = await storageService.uploadProviderPhoto(
            providerId: providerId,
            imageFile: _localPhotoFile!,
          );
        } catch (e) {
          // Si l'upload échoue (ex: bucket Storage non configuré), on continue sans photo
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur upload photo: ${e.toString()}. Le profil sera sauvegardé sans photo.'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          finalPhotoUrl = _photoUrl; // Garde l'ancienne photo ou null
        }
      }

      if (widget.existingProfile != null) {
        // Mise à jour
        final updatedProfile = widget.existingProfile!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          phone: _normalizePhoneNumber(_phoneController.text.trim()),
          email: _emailController.text.trim(),
          category: _categoryController.text.trim(),
          address: _addressController.text.trim(),
          photoUrl: finalPhotoUrl,
          lat: _lat,
          lng: _lng,
          geohash: _geohash,
          isPublished: _isPublished,
        );
        await repository.updateProfile(updatedProfile);
      } else {
        // Création
        final newProfile = ProviderProfile(
          ownerId: auth.user!.uid,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          phone: _normalizePhoneNumber(_phoneController.text.trim()),
          email: _emailController.text.trim(),
          category: _categoryController.text.trim(),
          address: _addressController.text.trim(),
          photoUrl: finalPhotoUrl,
          lat: _lat,
          lng: _lng,
          geohash: _geohash,
          isPublished: _isPublished,
        );
        await repository.create(newProfile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil enregistré avec succès')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProfile != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier mon profil' : 'Créer mon profil'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'NOM DE L\'ENTREPRISE OU DU PRESTATAIRE',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'DESCRIPTION',
                  prefixIcon: Icon(Icons.description_rounded),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'TÉLÉPHONE',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [_PhoneFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le téléphone est requis';
                  }
                  final normalized = _normalizePhoneNumber(value.trim());
                  if (!_isValidPhoneNumber(normalized)) {
                    return 'Numéro invalide. Format: +221 77 123 45 67 (indicatif international)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'EMAIL (OPTIONNEL)',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'CATÉGORIE',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _categoryController.text = value ?? '');
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La catégorie est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'ADRESSE',
                  prefixIcon: const Icon(Icons.location_on_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location_rounded),
                    onPressed: _detectLocation,
                    tooltip: 'Utiliser ma position actuelle',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'adresse est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Photo upload
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: _localPhotoFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      _localPhotoFile!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image_rounded, size: 48, color: AppTheme.textMuted),
                        );
                      },
                    ),
                  )
                      : _photoUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      _photoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, size: 48, color: AppTheme.textMuted),
                              SizedBox(height: 8),
                              Text('Photo non disponible', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                      : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text('Ajouter une photo', style: TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Publier mon profil'),
                subtitle: const Text('Rendre mon profil visible dans l\'annuaire'),
                value: _isPublished,
                onChanged: (value) {
                  setState(() => _isPublished = value);
                },
                activeTrackColor: AppTheme.accentColor.withValues(alpha: 0.5),
                activeThumbColor: AppTheme.accentColor,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.errorColor),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(isEditing ? 'Mettre à jour' : 'Créer mon profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formatter pour le numéro de téléphone international
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Supprime tous les caractères non numériques sauf le + au début
    var text = newValue.text.replaceAll(RegExp(r'[^0-9+]'), '');

    // Ajoute le + si pas présent
    if (!text.startsWith('+') && text.isNotEmpty) {
      text = '+$text';
    }

    // Limite à 15 chiffres (max international)
    final digitsOnly = text.replaceAll('+', '');
    if (digitsOnly.length > 15) {
      text = '+${digitsOnly.substring(0, 15)}';
    }

    // Formate avec espaces pour meilleure lisibilité
    // Format: +221 77 123 45 67
    String formatted = '';
    final digits = text.replaceAll('+', '');
    formatted = '+';
    
    for (int i = 0; i < digits.length; i++) {
      // Ajoute un espace après l'indicatif (3 premiers chiffres) et tous les 2 chiffres après
      if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) {
        formatted += ' ';
      }
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
