import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Dialogue explicatif pour la permission de localisation.
/// Affiché avant la demande système pour expliquer pourquoi l'app a besoin de la position.
class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const LocationPermissionDialog({
    super.key,
    required this.onAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: AppTheme.accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Autoriser la localisation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ServiceFinder utilise votre position pour:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          _BulletPoint(
            icon: Icons.search_rounded,
            text: 'Trouver les prestataires près de chez vous',
          ),
          SizedBox(height: 8),
          _BulletPoint(
            icon: Icons.map_rounded,
            text: 'Calculer les distances et vous montrer les plus proches',
          ),
          SizedBox(height: 8),
          _BulletPoint(
            icon: Icons.security_rounded,
            text: 'Votre position n\'est jamais stockée sur nos serveurs',
          ),
          SizedBox(height: 16),
          Text(
            'Vous pouvez refuser et utiliser la recherche manuelle par ville.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDeny,
          child: const Text('Refuser'),
        ),
        ElevatedButton(
          onPressed: onAllow,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 44),
          ),
          child: const Text('Autoriser'),
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletPoint({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.accentColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
