import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/poll_models.dart';
import '../services/admin_analytics_service.dart';
import '../widgets/analytics_widgets.dart';

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
                    children: [
                      _AnalyticsHero(summary: _summary),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Participation par consultation',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Taux calcule a partir des votes anonymes et de l\'objectif de participation.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.bar_chart_rounded,
                                      color: Color(0xFF0B6FA4)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (polls.isEmpty)
                                const Text('Aucune consultation disponible.')
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
                                archived: _summary.archivedCount,
                                draft: _summary.draftCount,
                              );
                              final legend = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Repartition des consultations',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Vue rapide de l\'etat du parc de consultations.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 18),
                                  _ChartLegendItem(
                                      color: const Color(0xFF0F9D58),
                                      label: 'Actifs',
                                      value: _summary.activeCount),
                                  _ChartLegendItem(
                                      color: const Color(0xFFF4A100),
                                      label: 'Clos',
                                      value: _summary.closedCount),
                                  _ChartLegendItem(
                                      color: const Color(0xFF64748B),
                                      label: 'Archives',
                                      value: _summary.archivedCount),
                                  _ChartLegendItem(
                                      color: const Color(0xFF0B6FA4),
                                      label: 'Brouillons',
                                      value: _summary.draftCount),
                                ],
                              );

                              if (wide) {
                                return Row(
                                  children: [
                                    Expanded(
                                        child: SizedBox(
                                            height: 260, child: chart)),
                                    const SizedBox(width: 24),
                                    Expanded(child: legend),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: 240, child: chart),
                                  const SizedBox(height: 16),
                                  legend
                                ],
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
                                  Text('Usage des acces citoyens',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 6),
                                  Text(
                                      'Synthese globale des codes citoyens actifs, utilises et des votes anonymes.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const SizedBox(height: 16),
                                  if (accessStats.isEmpty)
                                    const Text(
                                        'Aucun code citoyen n\'a encore ete genere.')
                                  else ...[
                                    _AccessUsageBarChart(stats: accessStats),
                                    const SizedBox(height: 18),
                                    for (final stat in accessStats)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
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
                                  Text('Votes sur 7 jours',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 6),
                                  Text(
                                      'Evolution quotidienne des votes traces.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const SizedBox(height: 16),
                                  _DailyVotesBarChart(dailyVotes: dailyVotes),
                                  const SizedBox(height: 18),
                                  for (final daily in dailyVotes)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
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
    required this.archived,
    required this.draft,
  });

  final int active;
  final int closed;
  final int archived;
  final int draft;

  @override
  Widget build(BuildContext context) {
    final total = active + closed + archived + draft;
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
              titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
            PieChartSectionData(
              value: closed.toDouble(),
              title: 'Clos\n$closed',
              color: const Color(0xFFF4A100),
              radius: 76,
              titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
            PieChartSectionData(
              value: archived.toDouble(),
              title: 'Archives\n$archived',
              color: const Color(0xFF64748B),
              radius: 76,
              titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
            PieChartSectionData(
              value: draft.toDouble(),
              title: 'Brouillons\n$draft',
              color: const Color(0xFF0B6FA4),
              radius: 76,
              titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
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
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}%',
                    style: const TextStyle(fontSize: 11)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 66,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visiblePolls.length)
                    return const SizedBox.shrink();
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
            final rate = poll.totalVoters == 0
                ? 0.0
                : (poll.totalVoted / poll.totalVoters) * 100;
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
    final maxVotes = dailyVotes.fold<int>(
        0, (maxValue, item) => item.votes > maxValue ? item.votes : maxValue);
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
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}',
                    style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailyVotes.length)
                    return const SizedBox.shrink();
                  return Text(dailyVotes[index].label,
                      style: const TextStyle(fontSize: 10));
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
    final maxTotal = visibleStats.fold<int>(
        0, (maxValue, item) => item.total > maxValue ? item.total : maxValue);
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
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}',
                    style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 54,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visibleStats.length)
                    return const SizedBox.shrink();
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
                BarChartRodData(
                    toY: stat.activated.toDouble(),
                    width: 10,
                    color: const Color(0xFF0B6FA4),
                    borderRadius: BorderRadius.circular(4)),
                BarChartRodData(
                    toY: stat.voted.toDouble(),
                    width: 10,
                    color: const Color(0xFF0F9D58),
                    borderRadius: BorderRadius.circular(4)),
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
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$value', style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({required this.summary});

  final AdminAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final participation = summary.averageParticipation;
    final votes7d = summary.votesLast7Days;
    final delta = summary.votesMomentumDelta;
    final spark = summary.votesSparkline;
    final conversion = summary.accessConversionRate;

    final gauge = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AnalyticsPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AnalyticsPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded,
                  color: AnalyticsPalette.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Pouls de la commune',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: ParticipationGauge(
              percentage: participation,
              label: 'Participation',
              subtitle:
                  '${summary.totalVotes} votes / ${summary.totalVoters} inscrits',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(
                  label: 'Actives',
                  value: '${summary.activeCount}',
                  color: const Color(0xFF0F9D58)),
              _MiniStat(
                  label: 'Clôturées',
                  value: '${summary.completedCount}',
                  color: const Color(0xFFF59E0B)),
              _MiniStat(
                  label: 'Brouillons',
                  value: '${summary.draftCount}',
                  color: AnalyticsPalette.slateMuted),
            ],
          ),
        ],
      ),
    );

    final kpis = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        AnalyticsKpiCard(
          label: 'VOTES 7 JOURS',
          value: '$votes7d',
          icon: Icons.how_to_vote_rounded,
          subtitle: 'sur les 7 derniers jours',
          sparkline: spark,
          delta: delta,
          accentColor: AnalyticsPalette.primary,
        ),
        AnalyticsKpiCard(
          label: 'CONVERSION ACCÈS → VOTE',
          value: '${conversion.toStringAsFixed(0)}%',
          icon: Icons.compare_arrows_rounded,
          subtitle:
              '${summary.totalUsedCodes} votes / ${summary.totalActivatedCodes} codes activés',
          accentColor: AnalyticsPalette.secondary,
        ),
        AnalyticsKpiCard(
          label: 'CODES CITOYENS ACTIFS',
          value: '${summary.totalValidatedCodes}',
          icon: Icons.qr_code_2_rounded,
          subtitle: 'générés à l\'accueil communal',
          accentColor: AnalyticsPalette.accent,
        ),
        AnalyticsKpiCard(
          label: 'CONSULTATIONS EN COURS',
          value: '${summary.activeCount}',
          icon: Icons.campaign_rounded,
          subtitle:
              '${summary.completedCount} clôturées · ${summary.draftCount} brouillons',
          accentColor: const Color(0xFF8B5CF6),
        ),
      ],
    );

    final funnel = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AnalyticsPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AnalyticsPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_rounded,
                  color: Color(0xFF6366F1), size: 18),
              const SizedBox(width: 8),
              Text(
                'Funnel d\'engagement citoyen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'De la création du code jusqu\'au vote exprimé.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          EngagementFunnel(
            steps: [
              FunnelStep(
                label: 'Codes générés',
                value: summary.totalValidatedCodes,
                hint: 'accès créés à l\'accueil',
              ),
              FunnelStep(
                label: 'Codes activés (connexion)',
                value: summary.totalActivatedCodes,
                hint: 'utilisés au moins une fois',
              ),
              FunnelStep(
                label: 'Votes exprimés',
                value: summary.totalUsedCodes,
                hint: 'vote anonymisé enregistré',
              ),
              FunnelStep(
                label: 'Objectif participation',
                value: summary.totalVoters,
                hint: 'inscrits ciblés',
              ),
            ],
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 300, child: gauge),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    kpis,
                    const SizedBox(height: 16),
                    funnel,
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            gauge,
            const SizedBox(height: 16),
            kpis,
            const SizedBox(height: 16),
            funnel,
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AnalyticsPalette.slateMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _PollParticipationRow extends StatelessWidget {
  const _PollParticipationRow({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final rate =
        poll.totalVoters == 0 ? 0.0 : poll.totalVoted / poll.totalVoters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(poll.projectTitle,
                    style: Theme.of(context).textTheme.titleSmall)),
            Text('${(rate * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: rate),
        const SizedBox(height: 6),
        Text(
            '${poll.totalVoted} votes sur ${poll.totalVoters} inscrits · statut ${poll.status}'),
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
        Text(
            'Codes utilises: ${stat.activated}/${stat.total} · Votes anonymes: ${stat.voted}'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: activationRate),
        const SizedBox(height: 8),
        LinearProgressIndicator(
            value: voteRate.clamp(0, 1),
            color: Theme.of(context).colorScheme.secondary),
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
