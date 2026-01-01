import 'package:flutter/material.dart';

class AppTheme {
  // Core colors
  static const Color seedColor = Color(0xFFD0BCFF);
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  
  // Accent colors
  static const Color accent = Colors.tealAccent;
  static const Color accentDim = Color(0x4D64FFDA); // tealAccent with 30% opacity
  
  // Type badge colors
  static const Color movieBadge = Colors.purple;
  static const Color tvBadge = Colors.blue;
  
  // Status colors
  static const Color statusWatching = Colors.tealAccent;
  static const Color statusCompleted = Colors.green;
  static const Color statusOnHold = Colors.orange;
  static const Color statusDropped = Colors.red;
  static const Color statusPlanned = Colors.blue;
  
  // Rating color
  static const Color ratingColor = Colors.amber;
  
  // Border radius standards
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusRound = 20.0;
  static const double radiusPill = 24.0;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        surface: background,
      ).copyWith(
        surface: background,
        surfaceContainer: surface,
      ),
      scaffoldBackgroundColor: background,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: accent.withAlpha(50),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: background,
        indicatorColor: accent.withAlpha(50),
        selectedIconTheme: const IconThemeData(color: accent),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
        labelType: NavigationRailLabelType.all,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: Colors.white.withAlpha(13)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      // FilterChip theme for modern chips
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: accent,
        disabledColor: surface,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        side: BorderSide(color: Colors.grey[700]!),
      ),
      // Input decoration for search bars
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
  
  // Helper for status color
  static Color getStatusColor(String status) {
    switch (status) {
      case 'watching':
        return statusWatching;
      case 'completed':
        return statusCompleted;
      case 'onHold':
        return statusOnHold;
      case 'dropped':
        return statusDropped;
      case 'planned':
        return statusPlanned;
      default:
        return Colors.grey;
    }
  }
  
  // Helper for gradient overlay
  static BoxDecoration get gradientOverlay => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black.withAlpha(200),
      ],
    ),
  );
}