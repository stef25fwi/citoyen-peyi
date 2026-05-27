import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/poll_service.dart';
import '../widgets/public_bottom_nav.dart';

/// Resultats publics anonymes des consultations.
///
/// Affiche les sondages ouverts, clotures ou archives rattaches a une commune.
/// Aucune donnee personnelle n'est exposee: seuls le nombre de votes par
/// option, le total et la commune sont restitues.
class PublicResultsPage extends StatefulWidget {
  const PublicResultsPage({super.key});

  @override
  State<PublicResultsPage> createState() => _PublicResultsPageState();
}

class _PublicResultsPageState extends State<PublicResultsPage> {
  bool _isLoading = true;
  List<PollModel> _polls = const [];
  String? _communeFilter;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final polls = await PollService.instance.loadPolls();
    if (!mounted) return;
    setState(() {
      _polls = polls;
      _isLoading = false;
    });
  }

  List<PollModel> get _filtered {
    return _polls.where((poll) {
      if (_communeFilter != null && _communeFilter!.isNotEmpty) {
        final matchById = poll.communeId == _communeFilter;
        final matchByName = poll.communeName.toLowerCase() == _communeFilter!.toLowerCase();
        if (!matchById && !matchByName) return false;
      }
      if (_statusFilter == 'open' && poll.status != 'active') return false;
      if (_statusFilter == 'closed' && poll.status != 'closed' && poll.status != 'archived') return false;
      return true;
    }).toList()
      ..sort((left, right) => right.openDate.compareTo(left.openDate));
  }

  Set<String> get _communes {
    final values = <String>{};
    for (final poll in _polls) {
      if (poll.communeName.isNotEmpty) values.add(poll.communeName);
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: const Text('Resultats publics')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Resultats anonymes des consultations',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Aucune donnee personnelle n\'est affichee. Seuls les totaux par option sont restitues.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A6573)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _communeFilter,
                        decoration: const InputDecoration(labelText: 'Commune'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Toutes')),
                          for (final commune in _communes)
                            DropdownMenuItem(value: commune, child: Text(commune)),
                        ],
                        onChanged: (value) => setState(() => _communeFilter = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Etat'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tous')),
                          DropdownMenuItem(value: 'open', child: Text('Ouvertes')),
                          DropdownMenuItem(value: 'closed', child: Text('Cloturees')),
                        ],
                        onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (filtered.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          const Icon(Icons.bar_chart_rounded, size: 42, color: Color(0xFF5A6573)),
                          const SizedBox(height: 12),
                          Text('Aucun resultat disponible', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 6),
                          const Text(
                            'Aucune consultation ne correspond aux filtres selectionnes.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final poll in filtered) _PollResultCard(poll: poll),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const PublicBottomNav(currentTab: PublicTab.results),
    );
  }
}

class _PollResultCard extends StatelessWidget {
  const _PollResultCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalVotes = poll.options.fold<int>(0, (sum, option) => sum + option.votes);
    final isClosed = poll.status == 'closed';
    final isArchived = poll.status == 'archived';
    final statusLabel = isArchived ? 'Archivee' : isClosed ? 'Cloturee' : 'Ouverte';
    final statusColor = isArchived ? const Color(0xFFE2E8F0) : isClosed ? const Color(0xFFE5E7EB) : const Color(0xFFDCFCE7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(poll.projectTitle, style: theme.textTheme.titleLarge)),
                  Chip(
                    label: Text(statusLabel),
                    backgroundColor: statusColor,
                  ),
                ],
              ),
              if (poll.communeName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(poll.communeName, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF5A6573))),
              ],
              if (poll.question.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(poll.question, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: 14),
              if (totalVotes == 0)
                const Text('Aucun vote enregistre pour le moment.')
              else
                for (final option in poll.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ResultBar(label: option.label, votes: option.votes, total: totalVotes),
                  ),
              const SizedBox(height: 8),
              Text(
                'Total des votes: $totalVotes${poll.totalVoters > 0 ? ' / ${poll.totalVoters} attendus' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF5A6573)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.label, required this.votes, required this.total});

  final String label;
  final int votes;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : votes / total;
    final percent = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('$votes  ·  $percent%', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF0F6D8F)),
          ),
        ),
      ],
    );
  }
}
