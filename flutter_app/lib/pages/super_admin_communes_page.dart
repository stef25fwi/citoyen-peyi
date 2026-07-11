import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/citizen_access_code_service.dart';
import '../services/poll_service.dart';
import '../services/super_admin_service.dart';

class SuperAdminCommunesPage extends StatefulWidget {
  const SuperAdminCommunesPage({super.key});

  @override
  State<SuperAdminCommunesPage> createState() => _SuperAdminCommunesPageState();
}

class _SuperAdminCommunesPageState extends State<SuperAdminCommunesPage> {
  bool _isLoading = true;
  List<CommuneAnalyticsModel> _communes = const [];
  List<PollModel> _polls = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    List<CommuneAnalyticsModel> communes = _communes;
    List<PollModel> polls = _polls;
    try {
      communes = await CitizenAccessCodeService.instance
          .getCommuneAnalyticsForSuperAdmin();

      // Un compte admin communal supprimé représente une commune retirée du
      // pilotage actif : on garde ses traces dans l'historique, mais on la
      // masque des statistiques courantes.
      final admins = await SuperAdminService.instance.loadProfiles();
      final activeKeys = admins
          .expand((admin) => [admin.communeCode, admin.communeName])
          .whereType<String>()
          .map((value) => value.trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toSet();
      communes = communes.where((commune) {
        final id = commune.communeId.trim().toLowerCase();
        final name = commune.communeName.trim().toLowerCase();
        return activeKeys.contains(id) || activeKeys.contains(name);
      }).toList();
    } catch (_) {
      // Conserve l'etat precedent en cas d'echec.
    }
    try {
      polls = await PollService.instance.loadPolls();
    } catch (_) {
      // Conserve l'etat precedent en cas d'echec.
    }
    if (!mounted) return;
    setState(() {
      _communes = communes;
      _polls = polls;
      _isLoading = false;
    });
  }

  Future<void> _editPoll(PollModel poll) async {
    await Navigator.of(context).pushNamed('/admin/polls/${poll.id}/edit');
    if (!mounted) return;
    await _load();
  }

  Future<void> _deletePoll(PollModel poll) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette consultation ?'),
        content: Text(
          'La consultation "${poll.projectTitle}" sera supprimée définitivement. '
          'Une consultation contenant déjà des votes ne peut pas être supprimée.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await PollService.instance.deletePoll(poll.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation supprimée.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
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
                Text('Pilotage multi-communes',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Vue consolidée des communes actives. Les communes dont le compte admin a été supprimé ne sont plus comptabilisées ici ; elles restent visibles dans l’historique des suppressions.',
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
                          'Aucune commune active disponible pour le moment.'),
                    ),
                  )
                else ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _TopStatCard(
                        label: 'Communes actives',
                        value: _communes.length.toString(),
                      ),
                      _TopStatCard(
                        label: 'Agents actifs',
                        value: _communes
                            .fold<int>(
                                0, (sum, item) => sum + item.activeControllers)
                            .toString(),
                      ),
                      _TopStatCard(
                        label: 'Codes générés',
                        value: _communes
                            .fold<int>(
                                0, (sum, item) => sum + item.codesGenerated)
                            .toString(),
                      ),
                      _TopStatCard(
                        label: 'Demandes en attente',
                        value: _communes
                            .fold<int>(
                                0, (sum, item) => sum + item.pendingRequests)
                            .toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  for (final commune in _communes)
                    _CommuneCard(commune: commune),
                ],
                if (!_isLoading) ...[
                  const SizedBox(height: 28),
                  Text('Consultations en ligne',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Toutes les consultations publiées, toutes communes confondues. '
                    'Cliquez pour les modifier ou les supprimer.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  if (_polls.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Aucune consultation en ligne pour le moment.'),
                      ),
                    )
                  else
                    for (final poll in _polls)
                      _PollAdminCard(
                        poll: poll,
                        onEdit: () => _editPoll(poll),
                        onDelete: () => _deletePoll(poll),
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

class _CommuneCard extends StatelessWidget {
  const _CommuneCard({required this.commune});

  final CommuneAnalyticsModel commune;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
                    child: Text(commune.communeName,
                        style: theme.textTheme.titleLarge),
                  ),
                  Chip(
                      label: Text(commune.communeId.isEmpty
                          ? 'Commune non codée'
                          : commune.communeId)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricChip(
                      label: 'Agents actifs',
                      value: commune.activeControllers.toString()),
                  _MetricChip(
                      label: 'Codes générés',
                      value: commune.codesGenerated.toString()),
                  _MetricChip(
                      label: 'Doublons détectés',
                      value: commune.duplicatesDetected.toString()),
                  _MetricChip(
                      label: 'Demandes pending',
                      value: commune.pendingRequests.toString()),
                  _MetricChip(
                      label: 'Taux doublons',
                      value: '${(commune.duplicateRate * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Dernier code généré : ${commune.lastCodeGeneratedAt ?? 'Aucune activité récente'}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: const Color(0xFF64748B)),
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
                    label: const Text('Voir activité'),
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
    );
  }
}

class _PollAdminCard extends StatelessWidget {
  const _PollAdminCard({
    required this.poll,
    required this.onEdit,
    required this.onDelete,
  });

  final PollModel poll;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static (String, Color) _statusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'open':
        return ('En ligne', const Color(0xFF15803D));
      case 'scheduled':
        return ('Programmée', const Color(0xFF0891B2));
      case 'closed':
        return ('Clôturée', const Color(0xFFB45309));
      case 'archived':
        return ('Archivée', const Color(0xFF6B7280));
      default:
        return ('Brouillon', const Color(0xFF6B7280));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = _statusBadge(poll.status);
    final commune = poll.communeName.isNotEmpty
        ? poll.communeName
        : (poll.communeId.isNotEmpty
            ? poll.communeId
            : 'Commune non renseignée');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      poll.projectTitle.isEmpty
                          ? 'Consultation'
                          : poll.projectTitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('$commune · ${poll.totalVoted} vote(s)',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF64748B))),
              if (poll.question.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(poll.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Supprimer'),
                  ),
                ],
              ),
            ],
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
