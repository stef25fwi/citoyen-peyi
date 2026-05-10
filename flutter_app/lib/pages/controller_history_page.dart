import 'package:flutter/material.dart';

import '../services/citizen_access_code_service.dart';

class ControllerHistoryPage extends StatefulWidget {
  const ControllerHistoryPage({super.key});

  @override
  State<ControllerHistoryPage> createState() => _ControllerHistoryPageState();
}

class _ControllerHistoryPageState extends State<ControllerHistoryPage> {
  bool _isLoading = true;
  List<CitizenAccessCodeModel> _codes = const [];
  List<DuplicateCodeRequestModel> _requests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      CitizenAccessCodeService.instance.loadAccessCodesForCurrentController(),
      CitizenAccessCodeService.instance.getDuplicateRequestsForCurrentController(status: 'all'),
    ]);
    if (!mounted) {
      return;
    }

    setState(() {
      _codes = results[0] as List<CitizenAccessCodeModel>;
      _requests = results[1] as List<DuplicateCodeRequestModel>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _requests.where((item) => item.status == 'pending').length;
    final approved = _requests.where((item) => item.status == 'approved').length;
    final rejected = _requests.where((item) => item.status == 'rejected').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique controleur'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/controleur/acces-citoyen'),
            child: const Text('Nouvel acces'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _HistoryMetric(label: 'Codes generes', value: '${_codes.length}', icon: Icons.vpn_key_rounded),
                    _HistoryMetric(label: 'Demandes en attente', value: '$pending', icon: Icons.hourglass_top_rounded),
                    _HistoryMetric(label: 'Demandes validees', value: '$approved', icon: Icons.check_circle_rounded),
                    _HistoryMetric(label: 'Demandes refusees', value: '$rejected', icon: Icons.cancel_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Codes citoyens generes', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Retrouvez les acces generes, leur statut et leur date de creation.'),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                        else if (_codes.isEmpty)
                          const Text('Aucun code citoyen genere pour le moment.')
                        else
                          for (final code in _codes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CodeHistoryTile(code: code),
                            ),
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
                        Text('Demandes de regeneration', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Suivi des doublons detectes et des decisions super administrateur.'),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                        else if (_requests.isEmpty)
                          const Text('Aucune demande de regeneration enregistree.')
                        else
                          for (final request in _requests)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DuplicateHistoryTile(request: request),
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

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

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
              Icon(icon, color: const Color(0xFF0F6D8F)),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeHistoryTile extends StatelessWidget {
  const _CodeHistoryTile({required this.code});

  final CitizenAccessCodeModel code;

  @override
  Widget build(BuildContext context) {
    final status = code.usedForLogin ? 'Utilise' : code.status;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E0EA)),
      ),
      child: ListTile(
        leading: const Icon(Icons.qr_code_2_rounded),
        title: Text(code.accessCode),
        subtitle: Text('${code.communeName} · ${code.createdAt}'),
        trailing: Chip(label: Text(status)),
      ),
    );
  }
}

class _DuplicateHistoryTile extends StatelessWidget {
  const _DuplicateHistoryTile({required this.request});

  final DuplicateCodeRequestModel request;

  @override
  Widget build(BuildContext context) {
    final title = switch (request.status) {
      'approved' => 'Validation accordee',
      'rejected' => 'Validation refusee',
      _ => 'Validation en attente',
    };

    final subtitle = request.status == 'approved'
        ? 'Nouveau code: ${request.newAccessCode ?? '-'}'
        : request.status == 'rejected'
            ? 'Motif de refus: ${request.rejectionReason ?? 'Non precise'}'
            : 'Motif demande: ${request.duplicateReason.label}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E0EA)),
      ),
      child: ListTile(
        leading: const Icon(Icons.content_copy_rounded),
        title: Text(title),
        subtitle: Text('${request.requestedAt}\n$subtitle'),
        isThreeLine: true,
        trailing: Chip(label: Text(request.status)),
      ),
    );
  }
}