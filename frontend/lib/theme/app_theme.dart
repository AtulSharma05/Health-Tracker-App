import 'package:flutter/material.dart';

class AppTheme {
  static const Color mint = Color(0xFFB8E6C4);
  static const Color peach = Color(0xFFFFD6B3);
  static const Color cream = Color(0xFFFFFAF3);
  static const Color avocado = Color(0xFF3D5A40);
  static const Color berry = Color(0xFF9D3C72);

  // Compatibility aliases used by imported workout UI modules.
  static const Color primaryGreen = avocado;
  static const Color primaryPink = peach;
  static const Color darkBrown = avocado;
  static const Color lightGreen = mint;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF9E9E9E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      primaryColor: avocado,
      colorScheme: ColorScheme.fromSeed(
        seedColor: avocado,
        primary: avocado,
        secondary: berry,
        surface: cream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: avocado,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: avocado),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: avocado,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
