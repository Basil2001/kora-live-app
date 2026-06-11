import 'package:flutter/material.dart';

class AppTheme {
  // Dark First Premium Colors
  static const Color darkBackground = Color(0xFF0B0E11);
  static const Color darkSurface = Color(0xFF151B22);
  static const Color darkSurfaceCard = Color(0xFF1E2630);
  
  static const Color accentGreen = Color(0xFF00E676); // Live indicator
  static const Color accentMint = Color(0xFF10B981);  // Positive stats
  static const Color accentCrimson = Color(0xFFFF3B30); // Cards/Live markers
  static const Color accentAmber = Color(0xFFFFCC00); // Warnings/Yellow cards
  
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color borderGrey = Color(0xFF2D3748);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF0F2F5);
  static const Color lightTextPrimary = Color(0xFF1A1D21);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorderGrey = Color(0xFFE5E7EB);
  static const Color lightAccentGreen = Color(0xFF059669);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentGreen,
        secondary: accentMint,
        surface: darkSurface,
        onSurface: textPrimary,
        error: accentCrimson,
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderGrey, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 14, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 12, color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: accentGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightAccentGreen,
        secondary: accentMint,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: accentCrimson,
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorderGrey, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightTextPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightTextPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary),
        bodyLarge: TextStyle(fontSize: 14, color: lightTextPrimary),
        bodyMedium: TextStyle(fontSize: 12, color: lightTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lightTextPrimary),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightAccentGreen,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
