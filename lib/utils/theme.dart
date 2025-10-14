import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32); // Green 800
  static const Color accentColor = Color(0xFF66BB6A); // Green 400
  static const Color errorColor = Color(0xFFD32F2F); // Red 700
  static const Color warningColor = Color(0xFFFFA000); // Amber 700
  static const Color textPrimaryColor = Color(0xFF212121); // Grey 900
  static const Color textSecondaryColor = Color(0xFF757575); // Grey 600
  static const Color backgroundColor = Color(0xFFF5F5F5); // Grey 100
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFBDBDBD); // Grey 400

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimaryColor),
        displayMedium: TextStyle(color: textPrimaryColor),
        displaySmall: TextStyle(color: textPrimaryColor),
        headlineMedium: TextStyle(color: textPrimaryColor),
        headlineSmall: TextStyle(color: textPrimaryColor),
        titleLarge: TextStyle(color: textPrimaryColor),
        titleMedium: TextStyle(color: textPrimaryColor),
        titleSmall: TextStyle(color: textPrimaryColor),
        bodyLarge: TextStyle(color: textPrimaryColor),
        bodyMedium: TextStyle(color: textPrimaryColor),
        bodySmall: TextStyle(color: textSecondaryColor),
        labelLarge: TextStyle(color: textPrimaryColor),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}