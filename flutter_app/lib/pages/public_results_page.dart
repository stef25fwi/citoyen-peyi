import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/citizen_public_access_service.dart';
import '../services/poll_service.dart';
import '../theme/citizen_design_tokens.dart';
import '../widgets/citizen/citizen_bottom_nav.dart';
import '../widgets/citizen/citizen_header.dart';
import '../widgets/citizen_connect_invite.dart';
import '../widgets/debug_log_viewer.dart';
import '../widgets/public_bottom_nav.dart';
import 'public_news_page.dart';

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
    List<PollModel> polls = const [];
    try {
      polls = await PollService.instance.loadPolls();
    } catch (_) {
      // PollService catche deja la plupart des erreurs reseau/Firestore ; ce
      // garde-fou evite un ecran bloque sur le spinner si un cas imprevu
      // remonte quand meme une exception.
      polls = const [];
    }
    if (!mounted) return;
    setState(() {
      _polls = polls;
      _isLoading = false;
    });
  }

  /// Statuts visibles publiquement : les brouillons et les consultations
  /// programmees (non encore publiees) ne doivent jamais apparaitre cote
  /// citoyen, meme si la lecture Firestore renvoie toute la collection.
  static const _publicStatuses = {'active', 'closed', 'archived'};

  /// Consultations reellement publiables (exclut draft / scheduled).
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
      if (_statusFilter == 'open' && poll.status != 'active') return false;
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
    final hasAnyPublicPoll = _publicPolls.isNotEmpty;
    final hasCitizenSession =
        CitizenPublicAccessService.instance.currentSession != null;

    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      body: _MobileFrame(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const CitizenHeader(
      title: 'Résultats des consultations',
      height: 92,
      trailing: DebugLogButton(label: ''),
    ),
              Expanded(
                child: RefreshIndicator(
                  color: CitizenDesignTokens.primaryBlue,
                  onRefresh: _load,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      if (!hasCitizenSession)
                        const CitizenConnectInvite(
                          message:
                              'Connectez-vous a votre compte pour participer aux consultations et suivre leurs resultats.',
                        )
                      else ...[
                        const _ResultsIntro(),
                        const SizedBox(height: 14),
                        if (hasAnyPublicPoll) ...[
                          _ResultsFilters(
                            communes: _communes,
                            communeFilter: _communeFilter,
                            statusFilter: _statusFilter,
                            onCommuneChanged: (value) =>
                                setState(() => _communeFilter = value),
                            onStatusChanged: (value) => setState(
                              () => _statusFilter = value ?? 'all',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_isLoading)
                          const _LoadingCard()
                        else if (filtered.isEmpty)
                          const _EmptyResultsCard()
                        else
                          for (final poll in filtered)
                            _PollResultCard(poll: poll),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: hasCitizenSession
          ? CitizenBottomNav(
              activeTab: CitizenNavTab.results,
              onTabSelected: _onCitizenNav,
            )
          : const PublicBottomNav(currentTab: PublicTab.results),
    );
  }

  void _onCitizenNav(CitizenNavTab tab) {
    switch (tab) {
      case CitizenNavTab.home:
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/citizen/welcome',
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

class _MobileFrame extends StatelessWidget {
  const _MobileFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: child,
      ),
    );
  }
}

class _ResultsIntro extends StatelessWidget {
  const _ResultsIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: CitizenDesignTokens.cardDecoration,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: CitizenDesignTokens.primaryBlue,
                size: 34,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Résultats anonymes',
                  style: TextStyle(
                    color: CitizenDesignTokens.textDark,
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Aucune donnée personnelle n’est affichée. Seuls les totaux par option sont restitués.',
            style: TextStyle(
              color: CitizenDesignTokens.textMuted,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: CitizenDesignTokens.cardDecoration,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: communeFilter,
            decoration: _fieldDecoration('Commune'),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('Toutes')),
              for (final commune in communes)
                DropdownMenuItem(value: commune, child: Text(commune)),
            ],
            onChanged: onCommuneChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: statusFilter,
            decoration: _fieldDecoration('État'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tous')),
              DropdownMenuItem(value: 'open', child: Text('Ouvertes')),
              DropdownMenuItem(value: 'closed', child: Text('Clôturées')),
            ],
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: CitizenDesignTokens.cardDecoration,
      child: const Center(
        child: CircularProgressIndicator(color: CitizenDesignTokens.primaryBlue),
      ),
    );
  }
}

class _EmptyResultsCard extends StatelessWidget {
  const _EmptyResultsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: CitizenDesignTokens.cardDecoration,
      child: const Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 42,
            color: CitizenDesignTokens.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            'Aucun résultat disponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CitizenDesignTokens.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Aucune consultation ne correspond aux filtres sélectionnés.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CitizenDesignTokens.textMuted,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            (sum, question) => sum +
                question.options.fold<int>(0, (inner, option) => inner + option.votes),
          );
    final statusLabel = _statusLabel(poll.status);
    final statusColor = _statusColor(poll.status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: CitizenDesignTokens.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: CitizenDesignTokens.skyBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.how_to_vote_rounded,
                  color: CitizenDesignTokens.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.projectTitle,
                      style: const TextStyle(
                        color: CitizenDesignTokens.textDark,
                        fontSize: 17,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (poll.communeName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        poll.communeName,
                        style: const TextStyle(
                          color: CitizenDesignTokens.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
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
              ),
            ],
          ),
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
                    question.title + (question.multiple ? ' (choix multiples)' : ''),
                    style: const TextStyle(
                      color: CitizenDesignTokens.textDark,
                      fontSize: 14.5,
                      height: 1.25,
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
                        : question.options
                            .fold<int>(0, (sum, option) => sum + option.votes),
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
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: CitizenDesignTokens.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
