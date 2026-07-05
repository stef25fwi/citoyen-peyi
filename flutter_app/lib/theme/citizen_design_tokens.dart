import 'package:flutter/material.dart';

class CitizenDesignTokens {
  const CitizenDesignTokens._();

  static const Color primaryBlue = Color(0xFF0077C8);
  static const Color deepBlue = Color(0xFF005A9C);
  static const Color skyBlue = Color(0xFFDFF5FF);
  static const Color lightBlue = Color(0xFFF2FAFF);
  static const Color yellow = Color(0xFFFFE060);
  static const Color yellowStrong = Color(0xFFFFD21F);
  static const Color textDark = Color(0xFF0B2F4A);
  static const Color textBlue = Color(0xFF005A9C);
  static const Color textMuted = Color(0xFF6B7C8F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE4F1FA);
  static const Color background = Color(0xFFF5FBFF);
  static const Color success = Color(0xFF1E9B62);

  static const double radiusLarge = 28;
  static const double radiusCard = 22;
  static const double radiusButton = 22;
  static const double radiusSmall = 14;
  static const double pagePadding = 20;
  static const double bottomNavHeight = 78;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0077C8),
      Color(0xFF0A8FDB),
      Color(0xFFDFF5FF),
    ],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0077C8),
      Color(0xFF005A9C),
    ],
  );

  static final List<BoxShadow> softShadow = [
    const BoxShadow(
      color: Color(0x1A005A9C),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: cardBorder),
    boxShadow: softShadow,
  );

  static final BoxDecoration softBlueDecoration = BoxDecoration(
    color: lightBlue,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: cardBorder),
  );

  static final BoxDecoration primaryButtonDecoration = BoxDecoration(
    color: yellow,
    borderRadius: BorderRadius.circular(radiusButton),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33005A9C),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
  );
}
