import 'package:flutter/material.dart';

import '../services/citizen_access_code_service.dart';
import '../services/super_admin_service.dart';

class SuperCommunesPage extends StatefulWidget {
  const SuperCommunesPage({super.key});

  @override
  State<SuperCommunesPage> createState() => _SuperCommunesPageState();
}

class _SuperCommunesPageState extends State<SuperCommunesPage> {
  bool _isLoading = true;
  List<CommuneAnalyticsModel> _communes = const [];
  List<AdminProfileModel> _admins = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      CitizenAccessCodeService.instance.getCommuneAnalyticsForSuperAdmin(),
      SuperAdminService.instance.loadProfiles(),
    ]);
    if (!mounted) return;
    setState(() {
      _communes = results[0] as List<CommuneAnalyticsModel>;
      _admins = results[1] as List<AdminProfileModel>;
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
          constraints: const BoxConstraints(maxWidth: 980),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Vue globale par commune',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Suivi des agents de mobilisation citoyenne, codes generes, doublons et admins communaux rattaches.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFF64748B)),
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
                      child: Text(
                          'Aucune activite de commune disponible pour le moment.'),
                    ),
                  )
                else
                  for (final commune in _communes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CommuneCard(
                        commune: commune,
                        adminCount: _adminCountFor(commune),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _adminCountFor(CommuneAnalyticsModel commune) {
    return _admins.where((admin) {
      final byCode =
          admin.communeCode != null && admin.communeCode == commune.communeId;
      final byName =
          admin.communeName.toLowerCase() == commune.communeName.toLowerCase();
      return byCode || byName;
    }).length;
  }
}

class _CommuneCard extends StatelessWidget {
  const _CommuneCard({required this.commune, required this.adminCount});

  final CommuneAnalyticsModel commune;
  final int adminCount;

  @override
  Widget build(BuildContext context) {
    final duplicateRate = (commune.duplicateRate * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    commune.communeName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (commune.communeId.isNotEmpty)
                  Chip(label: Text(commune.communeId)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(label: 'Admins', value: '$adminCount'),
                _MetricChip(
                    label: 'Agents actifs',
                    value: '${commune.activeControllers}'),
                _MetricChip(
                    label: 'Codes generes', value: '${commune.codesGenerated}'),
                _MetricChip(
                    label: 'Doublons', value: '${commune.duplicatesDetected}'),
                _MetricChip(
                    label: 'Demandes pending',
                    value: '${commune.pendingRequests}'),
                _MetricChip(label: 'Taux doublons', value: '$duplicateRate%'),
              ],
            ),
            if (commune.lastCodeGeneratedAt != null) ...[
              const SizedBox(height: 12),
              Text('Derniere activite: ${commune.lastCodeGeneratedAt}'),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pushNamed(
                      '/super/activity/commune/${commune.communeId}'),
                  child: const Text('Voir activite'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    '/super/activity',
                    arguments: {'communeId': commune.communeId},
                  ),
                  child: const Text('Filtrer activite'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/super/admins'),
                  child: const Text('Admins communaux'),
                ),
              ],
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}
