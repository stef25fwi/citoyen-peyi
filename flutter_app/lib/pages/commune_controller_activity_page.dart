import 'package:flutter/material.dart';

import '../services/citizen_access_code_service.dart';

class CommuneControllerActivityPage extends StatefulWidget {
  const CommuneControllerActivityPage({required this.communeId, super.key});

  final String communeId;

  @override
  State<CommuneControllerActivityPage> createState() => _CommuneControllerActivityPageState();
}

class _CommuneControllerActivityPageState extends State<CommuneControllerActivityPage> {
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final analytics = await CitizenAccessCodeService.instance.getControllerAnalytics(
      filters: ControllerActivityFilters(communeId: widget.communeId),
    );
    if (!mounted) return;
    setState(() {
      _analytics = analytics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final byController = <String, List<ControllerActivityLogModel>>{};
    for (final log in _analytics.logs) {
      byController.putIfAbsent(log.controllerId, () => []).add(log);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Controleurs de la commune')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('Controleurs', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    if (byController.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Aucun controleur actif pour cette commune.')))
                    else
                      for (final entry in byController.entries)
                        _ControllerCard(controllerId: entry.key, logs: entry.value),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ControllerCard extends StatelessWidget {
  const _ControllerCard({required this.controllerId, required this.logs});

  final String controllerId;
  final List<ControllerActivityLogModel> logs;

  @override
  Widget build(BuildContext context) {
    final name = logs.isEmpty ? controllerId : logs.first.controllerName;
    final generated = logs.where((item) => item.actionType == 'code_created').length;
    final duplicates = logs.where((item) => item.actionType == 'duplicate_detected').length;
    final pending = logs.where((item) => item.actionType == 'duplicate_request_created').length -
        logs.where((item) => item.actionType == 'regeneration_approved' || item.actionType == 'regeneration_rejected').length;
    final last = logs.isEmpty ? '-' : logs.first.createdAt;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.badge_rounded),
        title: Text(name),
        subtitle: Text(
          'Identifiant: $controllerId\nCodes generes: $generated · Doublons: $duplicates · Demandes en attente: ${pending < 0 ? 0 : pending}\nDerniere activite: $last',
        ),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/super/activity', arguments: {'controllerId': controllerId}),
          child: const Text('Voir activite'),
        ),
      ),
    );
  }
}