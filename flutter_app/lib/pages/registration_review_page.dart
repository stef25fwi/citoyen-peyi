import 'package:flutter/material.dart';

import '../services/auth_session_store.dart';

class RegistrationReviewPage extends StatelessWidget {
  const RegistrationReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AuthSessionStore.instance.currentSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscriptions'),
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
                      Text('Session active', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Text(
                        session == null
                            ? 'Aucune session chargee.'
                            : 'Role: ${session.role}\nProfil: ${session.label ?? 'Utilisateur'}\nCode: ${session.code ?? '-'}\nCommune: ${session.commune?.name ?? '-'}\nMode: ${session.modeLabel}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Cette page constitue l\'equivalent Flutter du point d\'entree controleur vers l\'interface de verification des pieces. Le branchement complet des workflows d\'inscription peut maintenant s\'appuyer sur la session admin ou controleur.',
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
