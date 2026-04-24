import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import '../services/auth_session_store.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AuthSessionStore.instance.currentSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord admin'),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuthService.instance.signOut();
              await AuthSessionStore.instance.clear();
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text('Deconnexion'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session administrateur', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Text(
                        session == null
                            ? 'Aucune session chargee.'
                            : 'Role: ${session.role}\nScope: ${session.adminScope ?? 'global'}\nProfil: ${session.label ?? 'Administrateur'}\nMode: ${session.modeLabel}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed('/admin/create'),
                    child: const Text('Creer un sondage'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pushNamed('/admin/inscriptions'),
                    child: const Text('Inscriptions'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pushNamed('/admin/analytics'),
                    child: const Text('Analytics'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Cette version Flutter utilise deja le backend d\'echange admin. Les pages metier restantes peuvent maintenant se brancher sur cette session.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
