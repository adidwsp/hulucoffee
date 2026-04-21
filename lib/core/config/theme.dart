// lib/core/config/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors Extracted from UI
  static const Color primary = Color(0xFF003466);
  static const Color primaryContainer = Color(0xFF1A4B84);
  static const Color primaryFixedDim = Color(0xFFA6C8FF);
  
  static const Color secondaryContainer = Color(0xFFFBDEB9);
  static const Color onSecondaryContainer = Color(0xFF766143);
  static const Color secondaryFixed = Color(0xFFFBDEB9);
  
  static const Color surface = Color(0xFFF9F9FB);
  static const Color surfaceVariant = Color(0xFFE2E2E4);
  static const Color surfaceContainerLow = Color(0xFFF3F3F5);
  static const Color surfaceContainer = Color(0xFFEEEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE8E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E4);
  
  static const Color background = Color(0xFFF9F9FB);
  static const Color error = Color(0xFFBA1A1A);
  
  // Text Colors
  static const Color onSurface = Color(0xFF1A1C1D);
  static const Color onSurfaceVariant = Color(0xFF424750);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  static const Color outline = Color(0xFF737781);
  static const Color outlineVariant = Color(0xFFC3C6D1);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: primaryContainer,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        surface: surface,
        surfaceVariant: surfaceVariant,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        error: error,
        onPrimary: onPrimary,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.manrope(
          textStyle: baseTextTheme.displayLarge,
          fontWeight: FontWeight.w900,
          color: primary,
        ),
        displayMedium: GoogleFonts.manrope(
          textStyle: baseTextTheme.displayMedium,
          fontWeight: FontWeight.w800,
          color: primary,
        ),
        displaySmall: GoogleFonts.manrope(
          textStyle: baseTextTheme.displaySmall,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        headlineLarge: GoogleFonts.manrope(
          textStyle: baseTextTheme.headlineLarge,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        headlineMedium: GoogleFonts.manrope(
          textStyle: baseTextTheme.headlineMedium,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        titleLarge: GoogleFonts.manrope(
          textStyle: baseTextTheme.titleLarge,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          textStyle: baseTextTheme.bodyLarge,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          textStyle: baseTextTheme.bodyMedium,
          color: onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          textStyle: baseTextTheme.labelLarge,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
