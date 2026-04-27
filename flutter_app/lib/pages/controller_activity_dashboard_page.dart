import 'package:flutter/material.dart';

import '../services/citizen_access_code_service.dart';

class ControllerActivityDashboardPage extends StatefulWidget {
  const ControllerActivityDashboardPage({super.key});

  @override
  State<ControllerActivityDashboardPage> createState() => _ControllerActivityDashboardPageState();
}

class _ControllerActivityDashboardPageState extends State<ControllerActivityDashboardPage> {
  bool _isLoading = true;
  ControllerActivityAnalytics _analytics = const ControllerActivityAnalytics(
    logs: [],
    totalCodesGenerated: 0,
    duplicatesDetected: 0,
    regenerationRequests: 0,
    regenerationsApproved: 0,
    regenerationsRejected: 0,
    loginCodesUsed: 0,
    activityByDay: {},
    activityByController: {},
  );
  List<CommuneAnalyticsModel> _communes = const [];
  String? _communeId;
  String? _controllerId;
  String? _actionType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final analytics = await CitizenAccessCodeService.instance.getControllerAnalytics(
      filters: ControllerActivityFilters(
        communeId: _communeId,
        controllerId: _controllerId,
        actionType: _actionType,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
    final communes = await CitizenAccessCodeService.instance.getCommuneAnalyticsForSuperAdmin();
    if (!mounted) return;
    setState(() {
      _analytics = analytics;
      _communes = communes..sort((left, right) => right.codesGenerated.compareTo(left.codesGenerated));
      _isLoading = false;
    });
  }

  Future<void> _selectDate({required bool start}) async {
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
    await _load();
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final controllerOptions = _analytics.logs
        .map((item) => (id: item.controllerId, name: item.controllerName))
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Activite des controleurs')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        initialValue: _communeId,
                        decoration: const InputDecoration(labelText: 'Commune'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Toutes')),
                          for (final commune in _communes)
                            DropdownMenuItem(value: commune.communeId, child: Text(commune.communeName)),
                        ],
                        onChanged: (value) {
                          setState(() => _communeId = value);
                          _load();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        initialValue: _controllerId,
                        decoration: const InputDecoration(labelText: 'Controleur'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Tous')),
                          for (final controller in controllerOptions)
                            DropdownMenuItem(value: controller.id, child: Text(controller.name)),
                        ],
                        onChanged: (value) {
                          setState(() => _controllerId = value);
                          _load();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        initialValue: _actionType,
                        decoration: const InputDecoration(labelText: 'Type action'),
                        items: const [
                          DropdownMenuItem<String>(value: null, child: Text('Toutes')),
                          DropdownMenuItem(value: 'code_created', child: Text('Code genere')),
                          DropdownMenuItem(value: 'duplicate_detected', child: Text('Doublon detecte')),
                          DropdownMenuItem(value: 'duplicate_request_created', child: Text('Demande regeneration')),
                          DropdownMenuItem(value: 'regeneration_approved', child: Text('Regeneration validee')),
                          DropdownMenuItem(value: 'regeneration_rejected', child: Text('Regeneration refusee')),
                          DropdownMenuItem(value: 'login_code_used', child: Text('Code utilise')),
                        ],
                        onChanged: (value) {
                          setState(() => _actionType = value);
                          _load();
                        },
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(start: true),
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(_startDate == null ? 'Date debut' : 'Debut ${_formatDate(_startDate!)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(start: false),
                      icon: const Icon(Icons.event_rounded),
                      label: Text(_endDate == null ? 'Date fin' : 'Fin ${_formatDate(_endDate!)}'),
                    ),
                    TextButton.icon(
                      onPressed: _startDate == null && _endDate == null ? null : _clearDates,
                      icon: const Icon(Icons.clear_rounded),
                      label: const Text('Effacer periode'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard('Codes generes', _analytics.totalCodesGenerated),
                      _StatCard('Doublons detectes', _analytics.duplicatesDetected),
                      _StatCard('Demandes regeneration', _analytics.regenerationRequests),
                      _StatCard('Regenerations validees', _analytics.regenerationsApproved),
                      _StatCard('Regenerations refusees', _analytics.regenerationsRejected),
                      _StatCard('Codes utilises', _analytics.loginCodesUsed),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 850;
                      final byDay = _ActivityBreakdownCard(
                        title: 'Activite par jour',
                        items: _analytics.activityByDay,
                        emptyText: 'Aucune activite sur la periode.',
                      );
                      final byController = _ActivityBreakdownCard(
                        title: 'Activite par controleur',
                        items: _analytics.activityByController,
                        emptyText: 'Aucun controleur actif sur la periode.',
                      );
                      if (!wide) {
                        return Column(children: [byDay, const SizedBox(height: 12), byController]);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: byDay),
                          const SizedBox(width: 12),
                          Expanded(child: byController),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Communes', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  for (final commune in _communes)
                    Card(
                      child: ListTile(
                        title: Text(commune.communeName),
                        subtitle: Text(
                          'Controleurs actifs: ${commune.activeControllers} · Codes: ${commune.codesGenerated} · '
                          'Doublons: ${commune.duplicatesDetected} · Pending: ${commune.pendingRequests} · '
                          'Taux doublons: ${(commune.duplicateRate * 100).round()}% · '
                          'Dernier code: ${commune.lastCodeGeneratedAt ?? '-'}',
                        ),
                        trailing: TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/super/activity/commune/${commune.communeId}'),
                          child: const Text('Voir commune'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text('Historique', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (_analytics.logs.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune activite.')))
                  else
                    for (final log in _analytics.logs.take(80))
                      Card(
                        child: ListTile(
                          title: Text('${log.actionType} · ${log.controllerName}'),
                          subtitle: Text('${log.communeName} · ${log.createdAt}\nCode: ${log.accessCode ?? '-'}'),
                          isThreeLine: true,
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

String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

class _ActivityBreakdownCard extends StatelessWidget {
  const _ActivityBreakdownCard({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final Map<String, int> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final sorted = items.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final maxValue = sorted.isEmpty ? 1 : sorted.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              Text(emptyText)
            else
              for (final entry in sorted.take(8))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text('${entry.value}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: entry.value / maxValue),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}