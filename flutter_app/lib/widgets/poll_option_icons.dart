import 'package:flutter/material.dart';

/// Catalogue des icones proposables sur une option de questionnaire.
/// Le slug est stocke en base et rendu cote citoyen dans le questionnaire
/// multi-etapes (voir vote_page.dart pour le rendu colore).
const List<(String, IconData, String)> kPollOptionIcons = [
  ('park', Icons.park_rounded, 'Parc'),
  ('lighting', Icons.light_rounded, 'Éclairage'),
  ('playground', Icons.attractions_rounded, 'Jeux'),
  ('pmr', Icons.accessible_rounded, 'PMR'),
  ('transport', Icons.directions_bus_rounded, 'Transport'),
  ('velo', Icons.pedal_bike_rounded, 'Vélo'),
  ('environnement', Icons.eco_rounded, 'Environnement'),
  ('eau', Icons.water_drop_rounded, 'Eau'),
  ('securite', Icons.shield_rounded, 'Sécurité'),
  ('culture', Icons.theater_comedy_rounded, 'Culture'),
  ('sport', Icons.sports_soccer_rounded, 'Sport'),
  ('sante', Icons.favorite_rounded, 'Santé'),
  ('ecole', Icons.school_rounded, 'École'),
  ('logement', Icons.home_rounded, 'Logement'),
  ('autre', Icons.more_horiz_rounded, 'Autre'),
];

IconData? pollIconForSlug(String slug) {
  for (final (s, icon, _) in kPollOptionIcons) {
    if (s == slug) return icon;
  }
  return null;
}

/// Illustration plate en couleur pour une option de questionnaire (voir
/// assets/citoyen_peyi/option_icons/), rendue cote citoyen dans le
/// questionnaire multi-etapes en remplacement de l'icone Material unie.
String? pollIllustrationForSlug(String slug) {
  if (slug.isEmpty) return null;
  for (final (s, _, _) in kPollOptionIcons) {
    if (s == slug) return 'assets/citoyen_peyi/option_icons/$slug.svg';
  }
  return null;
}

/// Feuille de selection d'icone commune aux editeurs de consultation.
Future<String?> showPollOptionIconPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Icône de l\'option',
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Aucune'),
                  onPressed: () => Navigator.pop(sheetContext, ''),
                ),
                for (final (slug, icon, label) in kPollOptionIcons)
                  ActionChip(
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    onPressed: () => Navigator.pop(sheetContext, slug),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
