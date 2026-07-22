import 'package:flutter/material.dart';

import 'citizen_design_tokens.dart';

/// Alias historiques conservés pour les écrans publics existants.
///
/// Toute nouvelle interface doit utiliser directement [CitizenDesignTokens].
/// Ces alias pointent désormais vers une seule palette afin d'éviter les
/// variations de bleu et de jaune entre les pages.
const cpBlueDark = CitizenDesignTokens.deepBlue;
const cpBlue = CitizenDesignTokens.primaryBlue;
const cpBlueLight = CitizenDesignTokens.skyBlue;
const cpBlueSoft = CitizenDesignTokens.lightBlue;
const cpYellow = CitizenDesignTokens.yellow;
const cpYellowStrong = CitizenDesignTokens.yellowStrong;
const cpWhite = CitizenDesignTokens.white;
const cpTextDark = CitizenDesignTokens.textDark;
const cpTextMuted = CitizenDesignTokens.textMuted;
const cpBorderWhite = Color(0xD9FFFFFF);

const String cpLogoPath =
    'assets/citoyen_peyi/logo_citoyen_peyi_transparent.webp';

bool isCompact(BuildContext context) {
  return MediaQuery.of(context).size.width < 700;
}
