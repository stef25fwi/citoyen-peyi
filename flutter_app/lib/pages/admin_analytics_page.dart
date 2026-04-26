import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/admin_analytics_service.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  bool _isLoading = true;
  AdminAnalyticsSummary _summary = const AdminAnalyticsSummary.empty();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    final summary = await AdminAnalyticsService.instance.loadSummary();

    if (!mounted) {
      return;
    }

    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final polls = _summary.polls;
    final accessStats = _summary.accessStats;
    final dailyVotes = _summary.dailyVotes;

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
                          _KpiCard(label: 'Votes emis', value: '${_summary.totalVotes}', subtitle: 'sur ${_summary.totalVoters} inscrits'),
                          _KpiCard(label: 'Participation moyenne', value: '${_summary.averageParticipation.round()}%', subtitle: 'sondages actifs et clos'),
                          _KpiCard(label: 'Sondages actifs', value: '${_summary.activeCount}', subtitle: '${_summary.closedCount} clos, ${_summary.draftCount} brouillons'),
                          _KpiCard(label: 'Codes valides', value: '${_summary.totalValidatedCodes}', subtitle: 'distribution en cours'),
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
                              if (polls.isEmpty)
                                const Text('Aucun sondage disponible.')
                              else
                                for (final poll in polls)
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
                                    if (accessStats.isEmpty)
                                      const Text('Aucun code valide n\'a encore ete charge.')
                                    else
                                      for (final stat in accessStats)
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
                                    for (final daily in dailyVotes)
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

  final PollAccessStats stat;

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

  final DailyVotesMetric daily;

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