import 'package:flutter/material.dart';

/// Constantes globales de design et de contenu (utils/).
class AppColors {
  static const Color primary = Color(0xFF0D5C56);
  static const Color primaryLight = Color(0xFF14847C);
  static const Color accent = Color(0xFFFF7A45);
  static const Color background = Color(0xFFF7F9FA);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1E2430);
  static const Color textGrey = Color(0xFF64748B);
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color border = Color(0xFFE2E8F0);
}

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textDark,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textGrey,
  );
}

class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 22;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Icônes associées à chaque catégorie de service (cohérence visuelle listes/cartes).
class CategoryIcons {
  static IconData iconFor(String category) {
    switch (category) {
      case 'Plomberie':
        return Icons.plumbing;
      case 'Électricité':
        return Icons.electrical_services;
      case 'Mécanique':
        return Icons.car_repair;
      case 'Coiffure':
        return Icons.content_cut;
      case 'Ménage':
        return Icons.cleaning_services;
      case 'Jardinage':
        return Icons.grass;
      case 'Menuiserie':
        return Icons.carpenter;
      case 'Peinture':
        return Icons.format_paint;
      case 'Informatique':
        return Icons.computer;
      default:
        return Icons.build;
    }
  }
}