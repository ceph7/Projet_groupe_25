import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../models/provider_profile.dart';

class ProviderDetailScreen extends StatelessWidget {
  final ProviderProfile provider;

  const ProviderDetailScreen({super.key, required this.provider});

  Future<void> _makePhoneCall() async {
    final phone = provider.phone;
    if (phone == null || phone.isEmpty) {
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Impossible de lancer l\'appel';
    }
  }

  Future<void> _sendSMS() async {
    final phone = provider.phone;
    if (phone == null || phone.isEmpty) {
      return;
    }
    final Uri smsUri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw 'Impossible de lancer l\'SMS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(provider.name),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec nom et catégorie
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (provider.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        provider.category!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Description
            if (provider.description != null && provider.description!.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.description!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Informations de contact
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Téléphone
            if (provider.phone != null && provider.phone!.isNotEmpty) ...[
              _ContactTile(
                icon: Icons.phone_rounded,
                label: 'Téléphone',
                value: provider.phone!,
                onTap: _makePhoneCall,
              ),
              const SizedBox(height: 12),
            ],
            
            // Email
            if (provider.email != null && provider.email!.isNotEmpty) ...[
              _ContactTile(
                icon: Icons.email_rounded,
                label: 'Email',
                value: provider.email!,
              ),
              const SizedBox(height: 12),
            ],
            
            // Adresse
            if (provider.address != null && provider.address!.isNotEmpty) ...[
              _ContactTile(
                icon: Icons.location_on_rounded,
                label: 'Adresse',
                value: provider.address!,
              ),
              const SizedBox(height: 24),
            ],
            
            // Boutons d'action
            Row(
              children: [
                if (provider.phone != null && provider.phone!.isNotEmpty) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _makePhoneCall,
                      icon: const Icon(Icons.phone_rounded),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (provider.phone != null && provider.phone!.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sendSMS,
                      icon: const Icon(Icons.message_rounded),
                      label: const Text('SMS'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Statut de publication
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: provider.isPublished
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: provider.isPublished
                      ? AppTheme.successColor
                      : Colors.grey[400]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.isPublished
                        ? Icons.check_circle_rounded
                        : Icons.info_rounded,
                    color: provider.isPublished
                        ? AppTheme.successColor
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.isPublished
                          ? 'Ce prestataire est actuellement disponible'
                          : 'Ce prestataire n\'est pas actuellement disponible',
                      style: TextStyle(
                        color: provider.isPublished
                            ? AppTheme.successColor
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          color: Colors.grey[50],
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
