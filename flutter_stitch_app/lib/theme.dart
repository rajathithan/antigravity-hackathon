import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Absolute Fine Dining Palette
  static const Color background = Color(0xFF000000); // Pure absolute black
  static const Color primary = Color(0xFFFF9933); // Saffron
  static const Color onPrimary = Color(0xFF000000);
  static const Color gold = Color(0xFFFFD700);
  static const Color surface = Color(0xFF050505);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color goldAccent = Color(0xFFC5A059);

  static ThemeData get eateryTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: goldAccent,
        surface: background,
        onSurface: onSurface,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 84,
          fontWeight: FontWeight.w900,
          color: onSurface,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 64,
          fontWeight: FontWeight.bold,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: goldAccent,
          letterSpacing: 4.0,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 22,
          color: Colors.white70,
          height: 1.6,
          fontWeight: FontWeight.w300,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: primary,
          letterSpacing: 4.0,
        ),
      ),
    );
  }
}
