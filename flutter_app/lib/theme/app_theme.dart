import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    const background = Color(0xFFF6F7F9);
    const foreground = Color(0xFF0F172A);
    const primary = Color(0xFF0D73F2);
    const accent = Color(0xFF20B69C);
    const success = Color(0xFF2BA66A);
    const warning = Color(0xFFF59E0B);
    const border = Color(0xFFE5E7EB);
    const muted = Color(0xFFF1F3F6);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      tertiary: success,
      error: const Color(0xFFDC2626),
      surface: Colors.white,
      onSurface: foreground,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, height: 1.05, color: foreground),
        headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: foreground),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: foreground),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: foreground),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: foreground),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: foreground),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: foreground),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: foreground),
        bodySmall: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF64748B)),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: foreground,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 18),
        iconTheme: const IconThemeData(color: foreground),
        shape: const Border(bottom: BorderSide(color: border)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shadowColor: border.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.4)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        helperStyle: textTheme.bodySmall,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        selectedColor: primary.withValues(alpha: 0.10),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.labelMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: border),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: muted,
      ),
    );
  }
}
