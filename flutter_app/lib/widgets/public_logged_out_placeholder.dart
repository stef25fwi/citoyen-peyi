import 'package:flutter/material.dart';

/// Etat visuel affiche sous la carte "Rejoignez votre espace" quand
/// l'utilisateur n'a pas encore sa session citoyenne.
///
/// Objectif : eviter une page vide tout en gardant le style bleu / blanc /
/// jaune de Citoyen Peyi et en expliquant ce qui apparaitra apres connexion.
class PublicLoggedOutPlaceholder extends StatelessWidget {
  const PublicLoggedOutPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.highlights = const <String>[],
  });

  final IconData icon;
  final String title;
  final String message;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FCFF), Color(0xFFEFF8FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFE7FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0756B8).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0756B8).withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF0878D8), size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5A6573),
              height: 1.35,
            ),
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final highlight in highlights)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFD8EAF7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF0F9F6E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          highlight,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF0756B8),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
