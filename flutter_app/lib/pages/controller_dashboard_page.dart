import 'package:flutter/material.dart';

import '../services/auth_session_store.dart';
import '../services/citizen_access_code_service.dart';
import '../services/firebase_auth_service.dart';

class ControllerDashboardPage extends StatefulWidget {
  const ControllerDashboardPage({super.key});

  @override
  State<ControllerDashboardPage> createState() => _ControllerDashboardPageState();
}

class _ControllerDashboardPageState extends State<ControllerDashboardPage> {
  bool _isLoading = true;
  List<CitizenAccessCodeModel> _codes = const [];
  List<DuplicateCodeRequestModel> _duplicates = const [];

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
    if (!mounted) return;
    setState(() {
      _codes = results[0] as List<CitizenAccessCodeModel>;
      _duplicates = results[1] as List<DuplicateCodeRequestModel>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionStore.instance.currentSession;
    final activeCodes = _codes.where((item) => item.status == 'active').length;
    final usedCodes = _codes.where((item) => item.usedForLogin).length;
    final pendingDuplicates = _duplicates.where((item) => item.status == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord controleur'),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuthService.instance.signOut();
              await AuthSessionStore.instance.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text('Deconnexion'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 28, child: Icon(Icons.badge_outlined)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(session?.label ?? 'Controleur', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text('Commune : ${session?.commune?.name ?? 'Non renseignee'}${session?.commune?.codePostal == null ? '' : ' · CP ${session!.commune!.codePostal}'}'),
                              Text('Mode ${session?.modeLabel ?? '-'} · role controller'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(label: 'Codes citoyens', value: '${_codes.length}', icon: Icons.vpn_key_rounded),
                    _MetricCard(label: 'Codes actifs', value: '$activeCodes', icon: Icons.verified_rounded),
                    _MetricCard(label: 'Votes publics', value: '$usedCodes', icon: Icons.how_to_vote_rounded),
                    _MetricCard(label: 'Doublons en attente', value: '$pendingDuplicates', icon: Icons.content_copy_rounded),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Parcours controleur', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        const _StepLine(index: 1, text: 'Verification physique de l\'eligibilite'),
                        const _StepLine(index: 2, text: 'Saisie des donnees minimales autorisees'),
                        const _StepLine(index: 3, text: 'Generation du code citoyen anonyme'),
                        const _StepLine(index: 4, text: 'Remise du code ou du QR au citoyen'),
                        const _StepLine(index: 5, text: 'Doublon eventuel : demande de regeneration'),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: () => Navigator.of(context).pushNamed('/controleur/acces-citoyen'),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text('Generer un acces citoyen'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => Navigator.of(context).pushNamed('/controleur/historique'),
                              icon: const Icon(Icons.history_rounded),
                              label: const Text('Voir mon historique'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Historique recent', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (_codes.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucun code citoyen genere.')))
                else
                  for (final code in _codes.take(8))
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.key_rounded),
                        title: Text(code.accessCode),
                        subtitle: Text('${code.communeName} · ${code.createdAt}\nStatut : ${code.status}${code.usedForLogin ? ' · vote public utilise' : ''}'),
                        isThreeLine: true,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

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
              Icon(icon, color: const Color(0xFF0D73F2)),
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

class _StepLine extends StatelessWidget {
  const _StepLine({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(radius: 13, child: Text('$index', style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
