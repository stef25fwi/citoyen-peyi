import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Participation par sondage', style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Graphique issu du tableau admin Flutter : taux calcule a partir des votants.',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.bar_chart_rounded, color: Color(0xFF0B6FA4)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (polls.isEmpty)
                                const Text('Aucun sondage disponible.')
                              else ...[
                                _PollParticipationBarChart(polls: polls),
                                const SizedBox(height: 18),
                                for (final poll in polls)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _PollParticipationRow(poll: poll),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 760;
                              final chart = _PollStatusPieChart(
                                active: _summary.activeCount,
                                closed: _summary.closedCount,
                                draft: _summary.draftCount,
                              );
                              final legend = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Repartition des sondages', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Vue rapide de l\'etat du parc de consultations.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 18),
                                  _ChartLegendItem(color: const Color(0xFF0F9D58), label: 'Actifs', value: _summary.activeCount),
                                  _ChartLegendItem(color: const Color(0xFFF4A100), label: 'Clos', value: _summary.closedCount),
                                  _ChartLegendItem(color: const Color(0xFF0B6FA4), label: 'Brouillons', value: _summary.draftCount),
                                ],
                              );

                              if (wide) {
                                return Row(
                                  children: [
                                    Expanded(child: SizedBox(height: 260, child: chart)),
                                    const SizedBox(width: 24),
                                    Expanded(child: legend),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [SizedBox(height: 240, child: chart), const SizedBox(height: 16), legend],
                              );
                            },
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
                                    const SizedBox(height: 6),
                                    Text('Barres activees / votees par sondage.', style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: 16),
                                    if (accessStats.isEmpty)
                                      const Text('Aucun code valide n\'a encore ete charge.')
                                    else ...[
                                      _AccessUsageBarChart(stats: accessStats),
                                      const SizedBox(height: 18),
                                      for (final stat in accessStats)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: _AccessUsageRow(stat: stat),
                                        ),
                                    ],
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
                                    const SizedBox(height: 6),
                                    Text('Evolution quotidienne des votes traces.', style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: 16),
                                    _DailyVotesBarChart(dailyVotes: dailyVotes),
                                    const SizedBox(height: 18),
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

class _PollStatusPieChart extends StatelessWidget {
  const _PollStatusPieChart({
    required this.active,
    required this.closed,
    required this.draft,
  });

  final int active;
  final int closed;
  final int draft;

  @override
  Widget build(BuildContext context) {
    final total = active + closed + draft;
    final sections = total == 0
        ? [
            PieChartSectionData(
              value: 1,
              title: '0',
              color: const Color(0xFFE2E8F0),
              radius: 72,
              titleStyle: Theme.of(context).textTheme.titleSmall,
            ),
          ]
        : [
            PieChartSectionData(
              value: active.toDouble(),
              title: 'Actifs\n$active',
              color: const Color(0xFF0F9D58),
              radius: 76,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            PieChartSectionData(
              value: closed.toDouble(),
              title: 'Clos\n$closed',
              color: const Color(0xFFF4A100),
              radius: 76,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            PieChartSectionData(
              value: draft.toDouble(),
              title: 'Brouillons\n$draft',
              color: const Color(0xFF0B6FA4),
              radius: 76,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 54,
        sections: sections,
      ),
    );
  }
}

class _PollParticipationBarChart extends StatelessWidget {
  const _PollParticipationBarChart({required this.polls});

  final List<PollModel> polls;

  @override
  Widget build(BuildContext context) {
    final visiblePolls = polls.take(8).toList();

    return SizedBox(
      height: 320,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(fontSize: 11)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 66,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visiblePolls.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 86,
                      child: Text(
                        visiblePolls[index].projectTitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(visiblePolls.length, (index) {
            final poll = visiblePolls[index];
            final rate = poll.totalVoters == 0 ? 0.0 : (poll.totalVoted / poll.totalVoters) * 100;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: rate.clamp(0, 100),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF0B6FA4),
                  width: 24,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _DailyVotesBarChart extends StatelessWidget {
  const _DailyVotesBarChart({required this.dailyVotes});

  final List<DailyVotesMetric> dailyVotes;

  @override
  Widget build(BuildContext context) {
    final maxVotes = dailyVotes.fold<int>(0, (maxValue, item) => item.votes > maxValue ? item.votes : maxValue);
    final maxY = maxVotes <= 0 ? 1.0 : maxVotes.toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailyVotes.length) return const SizedBox.shrink();
                  return Text(dailyVotes[index].label, style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          barGroups: List.generate(dailyVotes.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: dailyVotes[index].votes.toDouble(),
                  width: 18,
                  color: const Color(0xFF0F9D58),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _AccessUsageBarChart extends StatelessWidget {
  const _AccessUsageBarChart({required this.stats});

  final List<PollAccessStats> stats;

  @override
  Widget build(BuildContext context) {
    final visibleStats = stats.take(6).toList();
    final maxTotal = visibleStats.fold<int>(0, (maxValue, item) => item.total > maxValue ? item.total : maxValue);
    final maxY = maxTotal <= 0 ? 1.0 : maxTotal.toDouble();

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 54,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visibleStats.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 68,
                      child: Text(
                        visibleStats[index].pollName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(visibleStats.length, (index) {
            final stat = visibleStats[index];
            return BarChartGroupData(
              x: index,
              barsSpace: 4,
              barRods: [
                BarChartRodData(toY: stat.activated.toDouble(), width: 10, color: const Color(0xFF0B6FA4), borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: stat.voted.toDouble(), width: 10, color: const Color(0xFF0F9D58), borderRadius: BorderRadius.circular(4)),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$value', style: Theme.of(context).textTheme.titleSmall),
        ],
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