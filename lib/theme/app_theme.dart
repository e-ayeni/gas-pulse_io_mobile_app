import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B5E20);
  static const primaryLight = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF0D3B0F);
  static const accent = Color(0xFFFF6D00);
  static const surface = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const error = Color(0xFFD32F2F);

  // Gas level colors
  static const gasHigh = Color(0xFF2E7D32);
  static const gasMedium = Color(0xFFF9A825);
  static const gasLow = Color(0xFFE65100);
  static const gasCritical = Color(0xFFB71C1C);
  static const gasEmpty = Color(0xFF616161);

  // Liquid fill colors (semi-transparent for layered wave effect)
  static const liquidHigh = Color(0xFF43A047);
  static const liquidHighLight = Color(0xFF66BB6A);
  static const liquidMedium = Color(0xFFFDD835);
  static const liquidMediumLight = Color(0xFFFFEE58);
  static const liquidLow = Color(0xFFEF6C00);
  static const liquidLowLight = Color(0xFFFFA726);
  static const liquidCritical = Color(0xFFC62828);
  static const liquidCriticalLight = Color(0xFFEF5350);

  static Color gasColor(double? percent) {
    if (percent == null) return gasEmpty;
    if (percent > 50) return gasHigh;
    if (percent > 20) return gasMedium;
    if (percent > 10) return gasLow;
    return gasCritical;
  }

  static Color liquidColor(double? percent) {
    if (percent == null) return gasEmpty;
    if (percent > 50) return liquidHigh;
    if (percent > 20) return liquidMedium;
    if (percent > 10) return liquidLow;
    return liquidCritical;
  }

  static Color liquidColorLight(double? percent) {
    if (percent == null) return gasEmpty;
    if (percent > 50) return liquidHighLight;
    if (percent > 20) return liquidMediumLight;
    if (percent > 10) return liquidLowLight;
    return liquidCriticalLight;
  }
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primaryDark,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: AppColors.card,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
