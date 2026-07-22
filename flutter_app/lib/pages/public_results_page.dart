import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/citizen_public_access_service.dart';
import '../services/poll_service.dart';
import '../theme/citizen_design_tokens.dart';
import '../widgets/citizen/citizen_bottom_nav.dart';
import '../widgets/citizen_connect_invite.dart';
import '../widgets/public_bottom_nav.dart';
import '../widgets/public_page_ui.dart';
import 'public_news_page.dart';

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

  static const _publicStatuses = {
    'active',
    'open',
    'closed',
    'archived',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    List<PollModel> polls = const [];
    try {
      polls = await PollService.instance.loadPolls();
    } catch (_) {
      polls = const [];
    }
    if (!mounted) return;
    setState(() {
      _polls = polls;
      _isLoading = false;
    });
  }

  List<PollModel> get _publicPolls =>
      _polls.where((poll) => _publicStatuses.contains(poll.status)).toList();

  List<PollModel> get _filtered {
    return _publicPolls.where((poll) {
      if (_communeFilter != null && _communeFilter!.isNotEmpty) {
        final matchById = poll.communeId == _communeFilter;
        final matchByName =
            poll.communeName.toLowerCase() == _communeFilter!.toLowerCase();
        if (!matchById && !matchByName) return false;
      }
      if (_statusFilter == 'open' &&
          poll.status != 'active' &&
          poll.status != 'open') {
        return false;
      }
      if (_statusFilter == 'closed' &&
          poll.status != 'closed' &&
          poll.status != 'archived') {
        return false;
      }
      return true;
    }).toList()
      ..sort((left, right) => right.openDate.compareTo(left.openDate));
  }

  Set<String> get _communes {
    final values = <String>{};
    for (final poll in _publicPolls) {
      if (poll.communeName.isNotEmpty) values.add(poll.communeName);
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final session = CitizenPublicAccessService.instance.currentSession;
    final connected = session != null;

    return PublicPageShell(
      title: 'Résultats',
      navigationBar: connected
          ? CitizenBottomNav(
              activeTab: CitizenNavTab.results,
              onTabSelected: _onCitizenNav,
            )
          : const PublicBottomNav(currentTab: PublicTab.results),
      body: RefreshIndicator(
        color: CitizenDesignTokens.primaryBlue,
        onRefresh: _load,
        child: PublicResponsiveList(
          children: [
            if (!connected)
              const CitizenConnectInvite(
                message:
                    'Connectez-vous avec votre code citoyen pour participer anonymement et suivre les consultations de votre commune.',
              ),
            const PublicPageIntro(
              icon: Icons.bar_chart_rounded,
              title: 'Résultats des consultations',
              description:
                  'Consultez les résultats anonymes publiés. Aucune donnée personnelle n’est affichée.',
            ),
            const SizedBox(height: 14),
            if (!_isLoading && _publicPolls.isNotEmpty) ...[
              _ResultsFilters(
                communes: _communes,
                communeFilter: _communeFilter,
                statusFilter: _statusFilter,
                onCommuneChanged: (value) =>
                    setState(() => _communeFilter = value),
                onStatusChanged: (value) =>
                    setState(() => _statusFilter = value ?? 'all'),
              ),
              const SizedBox(height: 14),
            ],
            if (_isLoading)
              const PublicLoadingState()
            else if (filtered.isEmpty)
              const PublicEmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'Aucun résultat disponible',
                message:
                    'Aucune consultation publiée ne correspond aux filtres sélectionnés.',
              )
            else
              for (final poll in filtered) _PollResultCard(poll: poll),
          ],
        ),
      ),
    );
  }

  void _onCitizenNav(CitizenNavTab tab) {
    switch (tab) {
      case CitizenNavTab.home:
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/citizen/home',
          (route) => route.isFirst,
        );
        break;
      case CitizenNavTab.news:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PublicNewsPage()),
        );
        break;
      case CitizenNavTab.opinion:
        Navigator.of(context).pushNamed('/citizen/consultations');
        break;
      case CitizenNavTab.results:
        break;
    }
  }
}

class _ResultsFilters extends StatelessWidget {
  const _ResultsFilters({
    required this.communes,
    required this.communeFilter,
    required this.statusFilter,
    required this.onCommuneChanged,
    required this.onStatusChanged,
  });

  final Set<String> communes;
  final String? communeFilter;
  final String statusFilter;
  final ValueChanged<String?> onCommuneChanged;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final communeField = DropdownButtonFormField<String>(
      initialValue: communeFilter,
      isExpanded: true,
      decoration: _fieldDecoration('Commune'),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Toutes'),
        ),
        for (final commune in communes)
          DropdownMenuItem(
            value: commune,
            child: Text(
              commune,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onCommuneChanged,
    );
    final statusField = DropdownButtonFormField<String>(
      initialValue: statusFilter,
      isExpanded: true,
      decoration: _fieldDecoration('État'),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Tous')),
        DropdownMenuItem(value: 'open', child: Text('Ouvertes')),
        DropdownMenuItem(value: 'closed', child: Text('Clôturées')),
      ],
      onChanged: onStatusChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 620;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: CitizenDesignTokens.cardDecoration,
          child: horizontal
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: communeField),
                    const SizedBox(width: 12),
                    Expanded(child: statusField),
                  ],
                )
              : Column(
                  children: [
                    communeField,
                    const SizedBox(height: 12),
                    statusField,
                  ],
                ),
        );
      },
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: CitizenDesignTokens.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: CitizenDesignTokens.lightBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CitizenDesignTokens.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CitizenDesignTokens.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: CitizenDesignTokens.primaryBlue,
          width: 1.4,
        ),
      ),
    );
  }
}

class _PollResultCard extends StatelessWidget {
  const _PollResultCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.totalVoted > 0
        ? poll.totalVoted
        : poll.effectiveQuestions.fold<int>(
            0,
            (sum, question) =>
                sum +
                question.options.fold<int>(
                  0,
                  (inner, option) => inner + option.votes,
                ),
          );
    final statusLabel = _statusLabel(poll.status);
    final statusColor = _statusColor(poll.status);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final statusChip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusLabel,
            style: const TextStyle(
              color: CitizenDesignTokens.textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 40 : 44,
              height: compact ? 40 : 44,
              decoration: const BoxDecoration(
                color: CitizenDesignTokens.skyBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.how_to_vote_rounded,
                color: CitizenDesignTokens.primaryBlue,
                size: compact ? 22 : 24,
              ),
            ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poll.projectTitle,
                    style: const TextStyle(
                      color: CitizenDesignTokens.textDark,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (poll.communeName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      poll.communeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CitizenDesignTokens.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              statusChip,
            ],
          ],
        );

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(compact ? 16 : 18),
          decoration: CitizenDesignTokens.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (compact) ...[
                const SizedBox(height: 10),
                statusChip,
              ],
              const SizedBox(height: 16),
              if (totalVotes == 0)
                const Text(
                  'Aucun vote enregistré pour le moment.',
                  style: TextStyle(
                    color: CitizenDesignTokens.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                for (final question in poll.effectiveQuestions) ...[
                  if (question.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        question.title +
                            (question.multiple ? ' (choix multiples)' : ''),
                        style: const TextStyle(
                          color: CitizenDesignTokens.textDark,
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  for (final option in question.options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ResultBar(
                        label: option.label,
                        votes: option.votes,
                        total: poll.totalVoted > 0
                            ? poll.totalVoted
                            : question.options.fold<int>(
                                0,
                                (sum, option) => sum + option.votes,
                              ),
                      ),
                    ),
                ],
              const SizedBox(height: 8),
              Text(
                'Total des votes : $totalVotes${poll.totalVoters > 0 ? ' / ${poll.totalVoters} attendus' : ''}',
                style: const TextStyle(
                  color: CitizenDesignTokens.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    if (status == 'archived') return 'Archivée';
    if (status == 'closed') return 'Clôturée';
    return 'Ouverte';
  }

  Color _statusColor(String status) {
    if (status == 'archived') return const Color(0xFFE2E8F0);
    if (status == 'closed') return const Color(0xFFE5E7EB);
    return const Color(0xFFDCFCE7);
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.label,
    required this.votes,
    required this.total,
  });

  final String label;
  final int votes;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : votes / total;
    final clampedRatio = ratio.clamp(0.0, 1.0).toDouble();
    final percent = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CitizenDesignTokens.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$votes · $percent%',
              style: const TextStyle(
                color: CitizenDesignTokens.deepBlue,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: clampedRatio,
            minHeight: 9,
            backgroundColor: CitizenDesignTokens.skyBlue,
            valueColor: const AlwaysStoppedAnimation<Color>(
              CitizenDesignTokens.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}
