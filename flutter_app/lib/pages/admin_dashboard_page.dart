import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/poll_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_session_store.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  List<PollModel> _polls = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    final polls = await PollService.instance.loadPolls();
    if (!mounted) {
      return;
    }

    setState(() {
      _polls = polls;
      _isLoading = false;
    });
  }

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
          child: RefreshIndicator(
            onRefresh: _load,
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final actions = [
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
                  ];

                  if (wide) {
                    return Wrap(spacing: 12, runSpacing: 12, children: actions);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < actions.length; index++) ...[
                        actions[index],
                        if (index != actions.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
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
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Sondages recents', style: theme.textTheme.titleLarge),
                          ),
                          if (_isLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_isLoading && _polls.isEmpty)
                        const Text('Aucun sondage disponible pour le moment.')
                      else
                        for (final poll in _polls.take(5))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).pushNamed('/admin/poll/${poll.id}'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFD7E0EA)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(poll.projectTitle, style: theme.textTheme.titleMedium),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${poll.totalVoted}/${poll.totalVoters} votants · ${poll.status}',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
