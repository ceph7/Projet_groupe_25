import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Bannière de message (erreur, info, succès) réutilisable dans les formulaires.
/// Couvre l'issue #5 (affichage des messages d'erreur en français).
class MessageBanner extends StatelessWidget {
  final String message;
  final MessageBannerType type;

  const MessageBanner({
    super.key,
    required this.message,
    this.type = MessageBannerType.error,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = switch (type) {
      MessageBannerType.error => AppColors.error,
      MessageBannerType.success => AppColors.success,
      MessageBannerType.info => AppColors.primary,
    };
    final IconData icon = switch (type) {
      MessageBannerType.error => Icons.error_outline,
      MessageBannerType.success => Icons.check_circle_outline,
      MessageBannerType.info => Icons.info_outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

enum MessageBannerType { error, success, info }