library smartplot_theme;

import 'package:flutter/material.dart';

class SmartPlotTheme {
  // Brand Palette
  static const Color primaryEmerald = Color(0xFF059669);
  static const Color emeraldLight = Color(0xFF10B981);
  static const Color emeraldSubtle = Color(0xFFECFDF5);

  static const Color navyDark = Color(0xFF0F172A);
  static const Color navyText = Color(0xFF1E293B);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color slateLight = Color(0xFF94A3B8);

  static const Color bgPure = Color(0xFFFFFFFF);
  static const Color bgSurface = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE2E8F0);

  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);

  static const Color infoSky = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFE0F2FE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgSurface,
      colorScheme: const ColorScheme.light(
        primary: primaryEmerald,
        onPrimary: Colors.white,
        secondary: emeraldLight,
        surface: bgPure,
        onSurface: navyText,
        error: errorRed,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPure,
        foregroundColor: navyDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: navyDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: navyDark),
      ),
      cardTheme: CardThemeData(
        color: bgPure,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navyDark,
          side: const BorderSide(color: borderLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgPure,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryEmerald, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        hintStyle: const TextStyle(color: slateLight, fontSize: 14),
        labelStyle: const TextStyle(color: slateMuted, fontSize: 14),
      ),
    );
  }
}
