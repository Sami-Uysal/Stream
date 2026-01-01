import 'package:flutter/material.dart';

class AppTheme {
  static final Color _seedColor = const Color(0xFFD0BCFF); 
  static final Color _background = const Color(0xFF0A0A0A); 
  static final Color _surface = const Color(0xFF1E1E1E); 

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        surface: _background,
      ).copyWith(
        surface: _background,
        surfaceContainer: _surface,
      ),
      scaffoldBackgroundColor: _background,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _background,
        indicatorColor: _seedColor.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _background,
        indicatorColor: _seedColor.withValues(alpha: 0.2),
        selectedIconTheme: IconThemeData(color: _seedColor),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
        labelType: NavigationRailLabelType.all,
      ),
      cardTheme: CardTheme(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _background,
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
    );
  }
}