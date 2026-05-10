import 'package:flutter/material.dart';

import '../services/citizen_public_access_service.dart';
import '../widgets/public_bottom_nav.dart';

class CitizenDashboardPage extends StatelessWidget {
  const CitizenDashboardPage({
    this.initialSession,
    super.key,
  });

  final CitizenPublicAccessSession? initialSession;

  @override
  Widget build(BuildContext context) {
    final session = initialSession;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Espace citoyen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/access'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Votre code citoyen', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      Text(
                        'Votre code citoyen vous permet d\'acceder aux consultations ouvertes de votre commune. Votre vote est enregistre anonymement.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Votre identite n\'est pas liee a votre choix.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (session == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 44),
                        const SizedBox(height: 16),
                        Text('Acces citoyen requis', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                          'Saisissez un code citoyen valide pour consulter les consultations ouvertes de votre commune.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pushNamed('/access'),
                          child: const Text('Entrer mon code citoyen'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Commune: ${session.communeName}', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text('Consultations ouvertes: ${session.openPolls.length}'),
                        const SizedBox(height: 6),
                        Text('Consultations deja votees: ${session.votedPollIds.length}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Consultations ouvertes', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        if (session.openPolls.isEmpty)
                          const Text('Aucune consultation ouverte pour le moment.')
                        else
                          for (final poll in session.openPolls)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFD7E0EA)),
                                ),
                                child: ListTile(
                                  title: Text(poll.projectTitle),
                                  subtitle: Text(poll.question),
                                  trailing: session.hasVoted(poll.id)
                                      ? const Chip(label: Text('Deja vote'))
                                      : FilledButton(
                                          onPressed: () => Navigator.of(context).pushNamed(
                                            '/vote/${session.accessCode}?poll=${poll.id}',
                                          ),
                                          child: const Text('Voter'),
                                        ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PublicBottomNav(currentTab: PublicTab.vote),
    );
  }
}