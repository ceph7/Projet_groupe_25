import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs de marque
  static const Color primaryColor = Color(0xFF1B1710);   // encre chaude, remplace le bleu marine
  static const Color primaryLight = Color(0xFF2E271C);
  static const Color accentColor  = Color(0xFFC1440E);   // terracotta brûlé, remplace l'orange
  static const Color accentLight  = Color(0xFFD97A4A);

  // Surfaces
  static const Color backgroundColor = Colors.white;     // impératif, ne pas changer
  static const Color surfaceColor    = Colors.white;
  static const Color surfaceMuted    = Color(0xFFF7F5F1); // gris chaud très clair, pour inputs/sections, jamais pour le fond de Scaffold
  static const Color borderSubtle    = Color(0xFFE5DFD3); // gris chaud, remplace le slate froid

  // Texte
  static const Color textPrimary   = Color(0xFF1B1710);
  static const Color textSecondary = Color(0xFF6B6355);
  static const Color textMuted     = Color(0xFF9A9080);

  // Palette secondaire pour les catégories (dots/badges dans les listes)
  static const Color categorySage  = Color(0xFF6B7A4F);
  static const Color categoryOchre = Color(0xFFB8860B);

  // États (gardés proches du standard pour la reconnaissance universelle)
  static const Color errorColor   = Color(0xFFC1440E); // aligné sur l'accent pour cohérence de ton
  static const Color successColor = Color(0xFF4A7A4F);
  static const Color warningColor = Color(0xFFB8860B);

  static Color categoryColor(String category) {
    const palette = [accentColor, categorySage, categoryOchre];
    return palette[category.hashCode.abs() % palette.length];
  }

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        background: backgroundColor,
      ),
    );

    final textTheme = base.textTheme.copyWith(
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
        color: textPrimary,
        height: 1.15,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: textPrimary,
        height: 1.2,
      ),
      titleLarge: GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
        color: textPrimary,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: textSecondary,
        height: 1.4,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: textPrimary,
        height: 1.4,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: backgroundColor,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: primaryColor.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accentColor.withValues(alpha: 0.4),
          elevation: 0,
          shadowColor: accentColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.2);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.1);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: borderSubtle, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primaryColor.withValues(alpha: 0.06);
            }
            if (states.contains(WidgetState.hovered)) {
              return primaryColor.withValues(alpha: 0.03);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accentColor.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return accentColor.withValues(alpha: 0.05);
            }
            return null;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
        floatingLabelStyle: const TextStyle(color: accentColor, fontWeight: FontWeight.w600),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        focusColor: accentColor,
        hoverColor: surfaceMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        selectedColor: accentColor,
        labelStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        side: const BorderSide(color: borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        height: 66,
        indicatorColor: accentLight.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? accentColor : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? accentColor : textSecondary);
        }),
      ),
      dividerTheme: const DividerThemeData(color: borderSubtle, thickness: 1),
    );
  }
}