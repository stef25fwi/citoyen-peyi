import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.construction_rounded, size: 52, color: theme.colorScheme.primary),
                    const SizedBox(height: 18),
                    Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      subtitle ?? 'Cette route est branchee dans Flutter et attend maintenant le portage fonctionnel de son ecran React equivalent.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF5A6573)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pushNamed('/'),
                      child: const Text('Retour a l\'accueil'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
