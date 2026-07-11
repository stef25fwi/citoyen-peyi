import 'package:flutter/material.dart';

/// Palette et constantes partagées par les écrans publics Citoyen Peyi
/// (accueil, accès citoyen, ...) pour garder un rendu cohérent.
const cpBlueDark = Color(0xFF0756B8);
const cpBlue = Color(0xFF1A8FE8);
const cpBlueLight = Color(0xFFBFEFFF);
const cpBlueSoft = Color(0xFFEAF8FF);
const cpYellow = Color(0xFFFFD83D);
const cpYellowStrong = Color(0xFFFFC400);
const cpWhite = Color(0xFFFFFFFF);
const cpTextDark = Color(0xFF073F82);
const cpTextMuted = Color(0xFF65748B);
const cpBorderWhite = Color(0xBFFFFFFF);

const String cpLogoPath =
    'assets/citoyen_peyi/logo_citoyen_peyi_transparent.webp';

bool isCompact(BuildContext context) {
  return MediaQuery.of(context).size.width < 700;
}
