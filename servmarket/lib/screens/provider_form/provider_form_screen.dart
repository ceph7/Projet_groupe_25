import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/provider_profile.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/provider_repository.dart';

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
      
      if (widget.existingProfile != null) {
        // Mise à jour
        final updatedProfile = widget.existingProfile!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          category: _categoryController.text.trim(),
          address: _addressController.text.trim(),
          isPublished: _isPublished,
        );
        await repository.updateProfile(updatedProfile);
      } else {
        // Création
        final newProfile = ProviderProfile(
          ownerId: auth.user!.uid,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          category: _categoryController.text.trim(),
          address: _addressController.text.trim(),
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
        backgroundColor: Colors.white,
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
                  labelText: 'Nom de l\'entreprise ou du prestataire',
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
                  labelText: 'Description',
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
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le téléphone est requis';
                  }
                  if (value.trim().length < 10) {
                    return 'Numéro de téléphone invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
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
                value: _categoryController.text.isEmpty ? null : _categoryController.text,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
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
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  prefixIcon: Icon(Icons.location_on_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'adresse est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Publier mon profil'),
                subtitle: const Text('Rendre mon profil visible dans l\'annuaire'),
                value: _isPublished,
                onChanged: (value) {
                  setState(() => _isPublished = value);
                },
                activeColor: AppTheme.accentColor,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
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
