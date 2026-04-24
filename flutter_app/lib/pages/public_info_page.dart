import 'package:flutter/material.dart';

import '../widgets/public_bottom_nav.dart';

class PublicInfoPage extends StatelessWidget {
  const PublicInfoPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.currentTab,
    this.primaryActionLabel,
    this.primaryRoute,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final PublicTab currentTab;
  final String? primaryActionLabel;
  final String? primaryRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      ),
                      child: Icon(icon, size: 42, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF5A6573)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (primaryActionLabel != null && primaryRoute != null)
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed(primaryRoute!),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(primaryActionLabel!),
                          ),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pushNamed('/'),
                          child: const Text('Retour a l\'accueil'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: PublicBottomNav(currentTab: currentTab),
    );
  }
}