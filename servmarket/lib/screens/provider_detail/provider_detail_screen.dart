import 'package:flutter/material.dart';
import '../../models/provider_model.dart';
import '../../services/firestore_service.dart';
import '../../services/contact_service.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';
import '../chat/chat_screen.dart';

/// Écran de fiche détaillée d'un prestataire.
/// Couvre l'issue #10 (écran fiche détaillée prestataire), #22 (bouton
/// appeler), #23 (bouton SMS), #24 (aucune action automatique), #25
/// (message si action non supportée).
class ProviderDetailScreen extends StatefulWidget {
  final String providerId;

  const ProviderDetailScreen({super.key, required this.providerId});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  final _firestoreService = FirestoreService();
  final _contactService = ContactService();

  ProviderModel? _provider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = await _firestoreService.getProviderById(widget.providerId);
    setState(() {
      _provider = provider;
      _isLoading = false;
    });
  }

  /// Issue #24/#25 : action déclenchée uniquement par un appui explicite,
  /// avec message clair en cas d'échec.
  Future<void> _handleContactAction(Future<ContactActionResult> Function() action) async {
    final result = await action();
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Action impossible.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_provider == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Cette fiche n\'est plus disponible.')),
      );
    }

    final provider = _provider!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CategoryIcons.iconFor(provider.category),
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name, style: AppTextStyles.h1),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      provider.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (provider.description.isNotEmpty) ...[
                    Text('À propos', style: AppTextStyles.h2.copyWith(fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      provider.description,
                      style: AppTextStyles.body.copyWith(height: 1.5, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Appeler',
                          icon: Icons.call_rounded,
                          onPressed: () => _handleContactAction(
                            () => _contactService.call(provider.phone),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleContactAction(
                            () => _contactService.sendSms(provider.phone),
                          ),
                          icon: const Icon(Icons.sms_rounded, size: 20),
                          label: const Text('SMS'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: provider.ownerId,
                            otherUserName: provider.name,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Envoyer un message'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}