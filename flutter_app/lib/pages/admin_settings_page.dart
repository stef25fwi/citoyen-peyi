import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/admin_analytics_service.dart';
import '../services/auth_session_store.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _isLoading = true;
  AdminAnalyticsSummary _summary = const AdminAnalyticsSummary.empty();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summary = await AdminAnalyticsService.instance.loadSummary();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionStore.instance.currentSession;
    final commune = session?.commune;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Parametres de la commune'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  commune?.name ?? 'Commune non renseignee',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Vue de configuration communale et de readiness production. Les modifications critiques restent centralisees cote backend et Firestore.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(label: 'Consultations actives', value: _summary.activeCount.toString()),
                      _StatCard(label: 'Consultations cloturees', value: _summary.closedCount.toString()),
                      _StatCard(label: 'Codes citoyens actifs', value: _summary.totalValidatedCodes.toString()),
                      _StatCard(label: 'Votes enregistres', value: _summary.totalVotes.toString()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsCard(
                    title: 'Identite communale',
                    children: [
                      _SettingRow(label: 'Nom', value: commune?.name ?? 'Non renseigne'),
                      _SettingRow(label: 'Code commune', value: commune?.code ?? 'Non renseigne'),
                      _SettingRow(label: 'Code postal', value: commune?.codePostal ?? 'Non renseigne'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    title: 'Publication publique',
                    children: [
                      _SettingRow(label: 'API publique Flutter', value: AppConfig.apiBaseUrl),
                      const _SettingNote(
                        text: 'La page /news lit la collection public_news. Publiez les contenus cote Firestore pour alimenter l’interface publique.',
                      ),
                      const _SettingNote(
                        text: 'Les resultats publics sont anonymes: aucune identite citoyenne n’est exposee.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    title: 'Capacite et participation',
                    children: [
                      _SettingRow(label: 'Electeurs estimes', value: _summary.totalVoters.toString()),
                      _SettingRow(label: 'Votes comptabilises', value: _summary.totalVotes.toString()),
                      _SettingRow(
                        label: 'Participation moyenne',
                        value: '${_summary.averageParticipation.toStringAsFixed(1)}%',
                      ),
                      const _SettingNote(
                        text: 'Le nombre de votants estime est defini lors de la creation des consultations. Aucun stock de QR n’est genere depuis cet ecran.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    title: 'Actions rapides',
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed('/admin/polls/create'),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Nouvelle consultation'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed('/admin/controllers'),
                            icon: const Icon(Icons.groups_rounded),
                            label: const Text('Controleurs'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed('/admin/results'),
                            icon: const Icon(Icons.bar_chart_rounded),
                            label: const Text('Resultats'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 180, child: Text(label, style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SettingNote extends StatelessWidget {
  const _SettingNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
      ),
    );
  }
}