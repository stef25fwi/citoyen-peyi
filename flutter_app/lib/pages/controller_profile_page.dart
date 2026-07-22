import 'package:flutter/material.dart';

import '../services/auth_session_store.dart';
import '../services/citizen_access_code_service.dart';

class ControllerProfilePage extends StatefulWidget {
  const ControllerProfilePage({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  State<ControllerProfilePage> createState() => _ControllerProfilePageState();
}

class _ControllerProfilePageState extends State<ControllerProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = true;
  List<CitizenAccessCodeModel> _codes = const [];
  List<DuplicateCodeRequestModel> _requests = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    List<CitizenAccessCodeModel> codes = const [];
    List<DuplicateCodeRequestModel> requests = const [];

    try {
      final results = await Future.wait([
        CitizenAccessCodeService.instance.loadAccessCodesForCurrentController(),
        CitizenAccessCodeService.instance
            .getDuplicateRequestsForCurrentController(status: 'all'),
      ]).timeout(const Duration(seconds: 15));
      codes = results[0] as List<CitizenAccessCodeModel>;
      requests = results[1] as List<DuplicateCodeRequestModel>;
    } catch (_) {
      // L'onglet reste utilisable et permet un nouveau chargement manuel.
    }

    if (!mounted) return;
    setState(() {
      _codes = codes;
      _requests = requests;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline_rounded), text: 'Mon profil'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Mon activité'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _ControllerIdentityTab(),
          _ControllerActivityTab(
            isLoading: _isLoading,
            codes: _codes,
            requests: _requests,
            onRefresh: _load,
          ),
        ],
      ),
    );
  }
}

class _ControllerIdentityTab extends StatelessWidget {
  const _ControllerIdentityTab();

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionStore.instance.currentSession;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      child: Icon(Icons.badge_outlined, size: 38),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      session?.label ?? 'Agent de mobilisation citoyenne',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session?.commune?.name ?? 'Commune non renseignée',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rôle : agent de consultation citoyenne',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: const Text('Commune'),
                    subtitle: Text(
                      session?.commune?.name ?? 'Non renseignée',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Mode de connexion'),
                    subtitle: Text(session?.modeLabel ?? 'Non renseigné'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControllerActivityTab extends StatelessWidget {
  const _ControllerActivityTab({
    required this.isLoading,
    required this.codes,
    required this.requests,
    required this.onRefresh,
  });

  final bool isLoading;
  final List<CitizenAccessCodeModel> codes;
  final List<DuplicateCodeRequestModel> requests;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final entries = <_ActivityEntry>[
      for (final code in codes)
        _ActivityEntry(
          date: code.createdAt,
          icon: code.usedForLogin
              ? Icons.how_to_vote_rounded
              : Icons.qr_code_2_rounded,
          title: code.usedForLogin
              ? 'Code citoyen utilisé'
              : 'Code citoyen généré',
          subtitle:
              '${code.accessCode.isEmpty ? 'Accès citoyen' : code.accessCode} · ${code.status}',
        ),
      for (final request in requests)
        _ActivityEntry(
          date: request.requestedAt,
          icon: Icons.content_copy_rounded,
          title: switch (request.status) {
            'approved' => 'Régénération validée',
            'rejected' => 'Régénération refusée',
            _ => 'Demande de régénération créée',
          },
          subtitle: request.status == 'rejected'
              ? request.rejectionReason ?? 'Motif non précisé'
              : request.duplicateReason.label,
        ),
    ]..sort((left, right) => right.date.compareTo(left.date));

    final activeCodes = codes.where((item) => item.status == 'active').length;
    final usedCodes = codes.where((item) => item.usedForLogin).length;
    final pending = requests.where((item) => item.status == 'pending').length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 16) / 3;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActivityMetric(
                        width: width,
                        value: '${codes.length}',
                        label: 'Codes générés',
                      ),
                      _ActivityMetric(
                        width: width,
                        value: '$activeCodes',
                        label: 'Codes actifs',
                      ),
                      _ActivityMetric(
                        width: width,
                        value: '$usedCodes',
                        label: 'Codes utilisés',
                      ),
                      _ActivityMetric(
                        width: width,
                        value: '$pending',
                        label: 'Demandes en attente',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Historique de mon activité',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (entries.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'Aucune activité enregistrée pour cet agent.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                for (final entry in entries)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(entry.icon)),
                      title: Text(
                        entry.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${entry.subtitle}\n${entry.date}'),
                      isThreeLine: true,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.width,
    required this.value,
    required this.label,
  });

  final double width;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.clamp(140, 280),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.date,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String date;
  final IconData icon;
  final String title;
  final String subtitle;
}
