import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/poll_service.dart';
import '../services/vote_access_service.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  bool _isLoading = true;
  List<PollModel> _polls = const [];
  List<_PollAccessStats> _accessStats = const [];
  List<_DailyVotes> _dailyVotes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    final polls = await PollService.instance.loadPolls();
    final accessStats = <_PollAccessStats>[];
    final votesByDay = <String, int>{};

    for (final poll in polls) {
      final records = await VoteAccessService.instance.loadRecordsForPoll(poll.id);
      final activated = records.where((item) => item.activated).length;
      final voted = records.where((item) => item.hasVoted).length;
      accessStats.add(
        _PollAccessStats(
          pollId: poll.id,
          pollName: poll.projectTitle,
          total: records.length,
          activated: activated,
          voted: voted,
        ),
      );

      for (final record in records) {
        if (record.votedAt == null) {
          continue;
        }

        final key = record.votedAt!.split('T').first;
        votesByDay[key] = (votesByDay[key] ?? 0) + 1;
      }
    }

    final now = DateTime.now();
    final dailyVotes = List<_DailyVotes>.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final key = date.toIso8601String().split('T').first;
      return _DailyVotes(
        label: _weekdayLabel(date.weekday),
        votes: votesByDay[key] ?? 0,
      );
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _polls = polls;
      _accessStats = accessStats;
      _dailyVotes = dailyVotes;
      _isLoading = false;
    });
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return labels[(weekday - 1).clamp(0, labels.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes = _polls.fold<int>(0, (sum, poll) => sum + poll.totalVoted);
    final totalVoters = _polls.fold<int>(0, (sum, poll) => sum + poll.totalVoters);
    final activeCount = _polls.where((item) => item.status == 'active').length;
    final closedCount = _polls.where((item) => item.status == 'closed').length;
    final draftCount = _polls.where((item) => item.status == 'draft').length;
    final averageParticipation = _polls.where((item) => item.totalVoters > 0).isEmpty
        ? 0
        : (_polls
                    .where((item) => item.totalVoters > 0)
                    .map((item) => item.totalVoted / item.totalVoters)
                    .reduce((left, right) => left + right) /
                _polls.where((item) => item.totalVoters > 0).length) *
            100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytiques'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _KpiCard(label: 'Votes emis', value: '$totalVotes', subtitle: 'sur $totalVoters inscrits'),
                          _KpiCard(label: 'Participation moyenne', value: '${averageParticipation.round()}%', subtitle: 'sondages actifs et clos'),
                          _KpiCard(label: 'Sondages actifs', value: '$activeCount', subtitle: '$closedCount clos, $draftCount brouillons'),
                          _KpiCard(label: 'Codes valides', value: '${_accessStats.fold<int>(0, (sum, item) => sum + item.total)}', subtitle: 'distribution en cours'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Participation par sondage', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 16),
                              if (_polls.isEmpty)
                                const Text('Aucun sondage disponible.')
                              else
                                for (final poll in _polls)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _PollParticipationRow(poll: poll),
                                  ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          final left = Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Activation des acces', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 16),
                                    if (_accessStats.isEmpty)
                                      const Text('Aucun code valide n\'a encore ete charge.')
                                    else
                                      for (final stat in _accessStats)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: _AccessUsageRow(stat: stat),
                                        ),
                                  ],
                                ),
                              ),
                          );
                          final right = Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Votes sur 7 jours', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 16),
                                    for (final daily in _dailyVotes)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 14),
                                        child: _DailyVotesRow(daily: daily),
                                      ),
                                  ],
                                ),
                              ),
                          );

                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: left),
                                const SizedBox(width: 16),
                                Expanded(child: right),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [left, const SizedBox(height: 16), right],
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

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - 40;
    final cardWidth = availableWidth < 260 ? availableWidth : 220.0;

    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _PollParticipationRow extends StatelessWidget {
  const _PollParticipationRow({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final rate = poll.totalVoters == 0 ? 0.0 : poll.totalVoted / poll.totalVoters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(poll.projectTitle, style: Theme.of(context).textTheme.titleSmall)),
            Text('${(rate * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: rate),
        const SizedBox(height: 6),
        Text('${poll.totalVoted} votes sur ${poll.totalVoters} inscrits · statut ${poll.status}'),
      ],
    );
  }
}

class _AccessUsageRow extends StatelessWidget {
  const _AccessUsageRow({required this.stat});

  final _PollAccessStats stat;

  @override
  Widget build(BuildContext context) {
    final activationRate = stat.total == 0 ? 0.0 : stat.activated / stat.total;
    final voteRate = stat.total == 0 ? 0.0 : stat.voted / stat.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(stat.pollName, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('Actives: ${stat.activated}/${stat.total} · Votes: ${stat.voted}/${stat.total}'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: activationRate),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: voteRate, color: Theme.of(context).colorScheme.secondary),
      ],
    );
  }
}

class _DailyVotesRow extends StatelessWidget {
  const _DailyVotesRow({required this.daily});

  final _DailyVotes daily;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(daily.label)),
        Expanded(
          child: LinearProgressIndicator(
            value: daily.votes == 0 ? 0 : (daily.votes / 10).clamp(0, 1),
          ),
        ),
        const SizedBox(width: 12),
        Text('${daily.votes}'),
      ],
    );
  }
}

class _PollAccessStats {
  const _PollAccessStats({
    required this.pollId,
    required this.pollName,
    required this.total,
    required this.activated,
    required this.voted,
  });

  final String pollId;
  final String pollName;
  final int total;
  final int activated;
  final int voted;
}

class _DailyVotes {
  const _DailyVotes({required this.label, required this.votes});

  final String label;
  final int votes;
}