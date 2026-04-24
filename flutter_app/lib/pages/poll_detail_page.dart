import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/poll_service.dart';
import '../services/vote_access_service.dart';

class PollDetailPage extends StatefulWidget {
  const PollDetailPage({
    required this.pollId,
    super.key,
  });

  final String pollId;

  @override
  State<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends State<PollDetailPage> {
  bool _isLoading = true;
  PollModel? _poll;
  List<VoteAccessRecordModel> _records = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    final poll = await PollService.instance.loadPollById(widget.pollId);
    final records = poll == null
        ? const <VoteAccessRecordModel>[]
        : await VoteAccessService.instance.loadRecordsForPoll(poll.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _poll = poll;
      _records = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final poll = _poll;

    return Scaffold(
      appBar: AppBar(
        title: Text(poll?.projectTitle ?? 'Detail du sondage'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : poll == null
                  ? _EmptyPollState(onBack: () => Navigator.of(context).pushNamed('/admin'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _PollHeroCard(poll: poll),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 860;
                              final results = _ResultsCard(poll: poll);
                              final side = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _InfoCard(poll: poll),
                                  const SizedBox(height: 16),
                                  _QrCodesCard(records: _records),
                                  const SizedBox(height: 16),
                                  _AuditCard(records: _records),
                                ],
                              );

                              if (wide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 2, child: results),
                                    const SizedBox(width: 16),
                                    Expanded(child: side),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  results,
                                  const SizedBox(height: 16),
                                  side,
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _PollHeroCard extends StatelessWidget {
  const _PollHeroCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participation = poll.totalVoters == 0 ? 0.0 : poll.totalVoted / poll.totalVoters;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08354A), Color(0xFF0F6D8F)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.projectTitle,
              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              poll.question,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.84)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HeroStat(label: 'Statut', value: _statusLabel(poll.status)),
                _HeroStat(label: 'Participation', value: '${poll.totalVoted}/${poll.totalVoters}'),
                _HeroStat(label: 'Taux', value: '${(participation * 100).round()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'En cours';
      case 'closed':
        return 'Termine';
      default:
        return 'Brouillon';
    }
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.options.fold<int>(0, (sum, option) => sum + option.votes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultats agreges', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('$totalVotes vote(s) enregistres'),
            const SizedBox(height: 18),
            for (final option in poll.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ResultRow(option: option, totalVotes: totalVotes),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.option, required this.totalVotes});

  final PollOptionModel option;
  final int totalVotes;

  @override
  Widget build(BuildContext context) {
    final ratio = totalVotes == 0 ? 0.0 : option.votes / totalVotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(option.label, style: Theme.of(context).textTheme.titleSmall)),
            Text('${option.votes}'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: ratio),
        const SizedBox(height: 6),
        Text('${(ratio * 100).round()}% des suffrages'),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _InfoRow(label: 'Statut', value: poll.status),
            _InfoRow(label: 'Ouverture', value: poll.openDate),
            _InfoRow(label: 'Fermeture', value: poll.closeDate),
            _InfoRow(label: 'Participation', value: '${poll.totalVoted}/${poll.totalVoters}'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCodesCard extends StatelessWidget {
  const _QrCodesCard({required this.records});

  final List<VoteAccessRecordModel> records;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Codes d\'acces (${records.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (records.isEmpty)
              const Text('Aucun code n\'est encore associe a ce sondage.')
            else
              for (final record in records.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFFF7F9FC),
                      border: Border.all(color: const Color(0xFFD7E0EA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(record.code, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: 'monospace')),
                        const SizedBox(height: 6),
                        Text(_statusForRecord(record)),
                        const SizedBox(height: 6),
                        SelectableText('/vote/${record.code}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
            if (records.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+${records.length - 6} autres codes'),
              ),
          ],
        ),
      ),
    );
  }

  String _statusForRecord(VoteAccessRecordModel record) {
    if (record.hasVoted) {
      return 'Vote enregistre';
    }
    if (record.activated) {
      return 'Code active';
    }
    return 'Code valide';
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.records});

  final List<VoteAccessRecordModel> records;

  @override
  Widget build(BuildContext context) {
    final entries = records
        .where((item) => item.activatedAt != null || item.votedAt != null)
        .expand((item) {
          final nextEntries = <({String time, String label})>[];
          if (item.votedAt != null) {
            nextEntries.add((time: item.votedAt!, label: 'Vote anonyme enregistre'));
          }
          if (item.activatedAt != null) {
            nextEntries.add((time: item.activatedAt!, label: 'Code ${item.code} active'));
          }
          return nextEntries;
        })
        .toList()
      ..sort((left, right) => right.time.compareTo(left.time));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Journal d\'audit', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('Les acces et participations sont historises sans exposer le contenu des votes.'),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              const Text('Aucun evenement d\'audit pour le moment.')
            else
              for (final entry in entries.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 86,
                        child: Text(
                          entry.time.split('T').join(' '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.label)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPollState extends StatelessWidget {
  const _EmptyPollState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.poll_outlined, size: 42),
                const SizedBox(height: 16),
                Text('Sondage introuvable', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                const Text('Le sondage demande n\'existe pas ou n\'est plus disponible.'),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onBack,
                  child: const Text('Retour au tableau de bord'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}