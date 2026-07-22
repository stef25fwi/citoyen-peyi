import 'package:flutter/material.dart';

/// Source de vérité visuelle de Citoyen Peyi.
///
/// La palette reste institutionnelle et caribéenne : bleu de confiance,
/// surfaces lumineuses et jaune solaire réservé aux actions principales.
/// Les couleurs fonctionnelles ne doivent pas être utilisées comme couleurs
/// décoratives afin de préserver la lisibilité et l'accessibilité.
class CitizenDesignTokens {
  const CitizenDesignTokens._();

  // Marque et identité.
  static const Color primaryBlue = Color(0xFF0077C8);
  static const Color deepBlue = Color(0xFF005A9C);
  static const Color navy = Color(0xFF0B2F4A);
  static const Color skyBlue = Color(0xFFDFF5FF);
  static const Color lightBlue = Color(0xFFF2FAFF);
  static const Color yellow = Color(0xFFFFE060);
  static const Color yellowStrong = Color(0xFFFFD21F);

  // Surfaces et textes.
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F9FD);
  static const Color backgroundStrong = Color(0xFFEAF4FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8FBFD);
  static const Color surfaceBlue = Color(0xFFEDF8FE);
  static const Color textDark = Color(0xFF0B2F4A);
  static const Color textBlue = Color(0xFF005A9C);
  static const Color textMuted = Color(0xFF61768A);
  static const Color textSubtle = Color(0xFF8293A3);
  static const Color cardBorder = Color(0xFFDCEAF3);
  static const Color divider = Color(0xFFE6EFF5);

  // États sémantiques.
  static const Color success = Color(0xFF16845A);
  static const Color successSoft = Color(0xFFE8F7F0);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningSoft = Color(0xFFFFF5D9);
  static const Color error = Color(0xFFC43D4B);
  static const Color errorSoft = Color(0xFFFFEEF0);
  static const Color infoSoft = Color(0xFFE9F5FD);
  static const Color superAdminAccent = Color(0xFF5A58C9);
  static const Color superAdminSoft = Color(0xFFF0EFFF);

  // Rayons.
  static const double radiusLarge = 28;
  static const double radiusCard = 22;
  static const double radiusButton = 18;
  static const double radiusField = 16;
  static const double radiusSmall = 14;
  static const double radiusPill = 999;

  // Espacements.
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double pagePadding = 20;
  static const double bottomNavHeight = 78;

  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionStandard = Duration(milliseconds: 220);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF005A9C),
      Color(0xFF0077C8),
      Color(0xFF1697D4),
    ],
    stops: [0, 0.62, 1],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF004F89),
      Color(0xFF0077C8),
    ],
  );

  static const LinearGradient softBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8FCFF),
      Color(0xFFF1F8FC),
    ],
  );

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFE980),
      Color(0xFFFFD21F),
    ],
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x12004D7A),
      blurRadius: 26,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> raisedShadow = [
    BoxShadow(
      color: Color(0x1C004D7A),
      blurRadius: 30,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> navigationShadow = [
    BoxShadow(
      color: Color(0x18002F4A),
      blurRadius: 22,
      offset: Offset(0, -6),
    ),
  ];

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: cardBorder),
    boxShadow: softShadow,
  );

  static final BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: white.withValues(alpha: 0.9)),
    boxShadow: raisedShadow,
  );

  static final BoxDecoration softBlueDecoration = BoxDecoration(
    color: surfaceBlue,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: cardBorder),
  );

  static final BoxDecoration primaryButtonDecoration = BoxDecoration(
    gradient: actionGradient,
    borderRadius: BorderRadius.circular(radiusButton),
    boxShadow: const [
      BoxShadow(
        color: Color(0x2A8C6C00),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
  );
}