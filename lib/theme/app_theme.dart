import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central brand colors, pulled from the Mandi-Go reference design.
class AppColors {
  static const primary = Color(0xFF1E6B3A); // Mandi-Go green
  static const primaryDark = Color(0xFF0F4224);
  static const primaryLight = Color(0xFFE8F3EC);
  static const accent = Color(0xFF4CAF6D);
  static const background = Color(0xFFF6F8F7);
  static const surface = Colors.white;
  static const textDark = Color(0xFF1A1D1B);
  static const textGrey = Color(0xFF6B7280);
  static const border = Color(0xFFEBEEEC);
  static const amber = Color(0xFFF5A623);
  static const purple = Color(0xFF7C6FE0);
  static const blue = Color(0xFF3B82F6);
  static const red = Color(0xFFE05353);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E6B3A), Color(0xFF0F4224)],
  );
}

/// Reusable soft-shadow decorations so every card looks consistent.
class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> lifted = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10)),
  ];
  static List<BoxShadow> coloredGreen = [
    BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8)),
  ];
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
