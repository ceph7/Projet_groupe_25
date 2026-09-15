import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/provider_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../widgets/ticket_badge_clipper.dart';
import '../service_request/service_request_screen.dart';
import '../messaging/conversation_screen.dart';

class ProviderDetailScreen extends StatefulWidget {
  final ProviderProfile provider;

  const ProviderDetailScreen({super.key, required this.provider});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  Future<void> _makePhoneCall() async {
    final phone = widget.provider.phone;
    if (phone == null || phone.isEmpty) {
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de lancer l\'appel sur cet appareil'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _sendSMS() async {
    final phone = widget.provider.phone;
    if (phone == null || phone.isEmpty) {
      return;
    }
    final Uri smsUri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de lancer un SMS sur cet appareil'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openMessaging() async {
    final authProvider = context.read<AuthProvider>();
    final messagingProvider = context.read<MessagingProvider>();

    if (!mounted) return;

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour envoyer un message')),
      );
      return;
    }

    if (widget.provider.ownerId == authProvider.currentUser!.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous ne pouvez pas vous envoyer un message à vous-même')),
      );
      return;
    }

    try {
      await messagingProvider.openConversation(
        authProvider.currentUser!.uid,
        widget.provider.ownerId,
      );

      if (mounted && messagingProvider.currentConversation != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              conversation: messagingProvider.currentConversation!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provider.name),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final isOwner = auth.currentUser?.uid == widget.provider.ownerId;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              return SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo du prestataire
                if (widget.provider.photoUrl != null && widget.provider.photoUrl!.isNotEmpty) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.provider.photoUrl!,
                        width: isTablet ? 280 : 200,
                        height: isTablet ? 280 : 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: isTablet ? 280 : 200,
                            height: isTablet ? 280 : 200,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: isTablet ? 280 : 200,
                            height: isTablet ? 280 : 200,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.business_rounded,
                              size: 80,
                              color: AppTheme.textMuted,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Header avec nom et catégorie
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.provider.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          fontSize: isTablet ? 28 : 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.provider.category != null) ...[
                        ClipPath(
                          clipper: TicketBadgeClipper(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: isTablet ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.provider.category!.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: isTablet ? 12 : 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                if (widget.provider.description != null && widget.provider.description!.isNotEmpty) ...[
                  Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.provider.description!,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Informations de contact
                Text(
                  'CONTACT',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Téléphone
                if (widget.provider.phone != null && widget.provider.phone!.isNotEmpty) ...[
                  _ContactTile(
                    icon: Icons.phone_rounded,
                    label: 'TÉLÉPHONE',
                    value: widget.provider.phone!,
                    onTap: _makePhoneCall,
                  ),
                  const SizedBox(height: 12),
                ],

                // Email
                if (widget.provider.email != null && widget.provider.email!.isNotEmpty) ...[
                  _ContactTile(
                    icon: Icons.email_rounded,
                    label: 'EMAIL',
                    value: widget.provider.email!,
                  ),
                  const SizedBox(height: 12),
                ],

                // Adresse
                if (widget.provider.address != null && widget.provider.address!.isNotEmpty) ...[
                  _ContactTile(
                    icon: Icons.location_on_rounded,
                    label: 'ADRESSE',
                    value: widget.provider.address!,
                  ),
                  const SizedBox(height: 12),
                ],

                // Coordonnées GPS
                if (widget.provider.lat != null && widget.provider.lng != null) ...[
                  _ContactTile(
                    icon: Icons.my_location_rounded,
                    label: 'COORDONNÉES GPS',
                    value: '${widget.provider.lat!.toStringAsFixed(6)}, ${widget.provider.lng!.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 24),
                ],

                // Boutons d'action (uniquement pour les clients, pas pour le propriétaire)
                if (!isOwner) ...[
                  Row(
                    children: [
                      if (widget.provider.phone != null && widget.provider.phone!.isNotEmpty) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _makePhoneCall,
                            icon: const Icon(Icons.phone_rounded),
                            label: const Text('APPELER'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.fromHeight(isTablet ? 60 : 52),
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 20 : 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                      ],
                      if (widget.provider.phone != null && widget.provider.phone!.isNotEmpty) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _sendSMS,
                            icon: const Icon(Icons.message_rounded),
                            label: const Text('SMS'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.fromHeight(isTablet ? 60 : 52),
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 20 : 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openMessaging,
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text('MESSAGE'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(isTablet ? 60 : 52),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 20 : 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bouton Demander un service — plat, couleur accent unie (pas de dégradé)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ServiceRequestScreen(provider: widget.provider),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'DEMANDER UN SERVICE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                // Statut de publication
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.provider.isPublished
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.provider.isPublished
                          ? AppTheme.successColor
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.provider.isPublished
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        color: widget.provider.isPublished
                            ? AppTheme.successColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.provider.isPublished
                              ? 'Ce prestataire est actuellement disponible'
                              : 'Ce prestataire n\'est pas actuellement disponible',
                          style: TextStyle(
                            color: widget.provider.isPublished
                                ? AppTheme.successColor
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
            },
          );
        },
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppTheme.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
