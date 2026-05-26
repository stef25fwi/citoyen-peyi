import 'package:flutter/material.dart';

import '../services/citizen_access_code_service.dart';

class SuperAdminCommunesPage extends StatefulWidget {
  const SuperAdminCommunesPage({super.key});

  @override
  State<SuperAdminCommunesPage> createState() => _SuperAdminCommunesPageState();
}

class _SuperAdminCommunesPageState extends State<SuperAdminCommunesPage> {
  bool _isLoading = true;
  List<CommuneAnalyticsModel> _communes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final communes = await CitizenAccessCodeService.instance.getCommuneAnalyticsForSuperAdmin();
    if (!mounted) return;
    setState(() {
      _communes = communes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Communes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Pilotage multi-communes', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Vue consolidee des communes actives, basee sur les logs des agents de mobilisation citoyenne et les demandes de doublons deja disponibles dans la plateforme.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_communes.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucune activite communale disponible pour le moment.'),
                    ),
                  )
                else ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _TopStatCard(
                        label: 'Communes suivies',
                        value: _communes.length.toString(),
                      ),
                      _TopStatCard(
                        label: 'Agents actifs',
                        value: _communes.fold<int>(0, (sum, item) => sum + item.activeControllers).toString(),
                      ),
                      _TopStatCard(
                        label: 'Codes generes',
                        value: _communes.fold<int>(0, (sum, item) => sum + item.codesGenerated).toString(),
                      ),
                      _TopStatCard(
                        label: 'Demandes en attente',
                        value: _communes.fold<int>(0, (sum, item) => sum + item.pendingRequests).toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  for (final commune in _communes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(commune.communeName, style: theme.textTheme.titleLarge),
                                  ),
                                  Chip(label: Text(commune.communeId.isEmpty ? 'Commune non codee' : commune.communeId)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _MetricChip(label: 'Agents actifs', value: commune.activeControllers.toString()),
                                  _MetricChip(label: 'Codes generes', value: commune.codesGenerated.toString()),
                                  _MetricChip(label: 'Doublons detectes', value: commune.duplicatesDetected.toString()),
                                  _MetricChip(label: 'Demandes pending', value: commune.pendingRequests.toString()),
                                  _MetricChip(label: 'Taux doublons', value: '${(commune.duplicateRate * 100).round()}%'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Dernier code genere: ${commune.lastCodeGeneratedAt ?? 'Aucune activite recente'}',
                                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: () => Navigator.of(context).pushNamed(
                                      '/super/activity/commune/${commune.communeId}',
                                    ),
                                    icon: const Icon(Icons.analytics_rounded),
                                    label: const Text('Voir activite'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).pushNamed(
                                      '/super/activity',
                                      arguments: {'communeId': commune.communeId},
                                    ),
                                    icon: const Icon(Icons.filter_alt_rounded),
                                    label: const Text('Filtrer le tableau'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _TopStatCard extends StatelessWidget {
  const _TopStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}