import 'package:flutter/material.dart';

import '../../models/poll_models.dart';
import '../../services/citizen_public_access_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_bottom_nav.dart';
import '../../widgets/citizen/citizen_header.dart';
import '../../widgets/citizen/consultation_card.dart';
import 'citizen_home_page.dart';
import 'citizen_poll_question_page.dart';

class CitizenConsultationsPage extends StatefulWidget {
  const CitizenConsultationsPage({
    super.key,
    this.initialSession,
  });

  final CitizenPublicAccessSession? initialSession;

  @override
  State<CitizenConsultationsPage> createState() =>
      _CitizenConsultationsPageState();
}

class _CitizenConsultationsPageState extends State<CitizenConsultationsPage> {
  int selectedFilter = 0;

  static const List<_ConsultationDemo> _fallbackConsultations = [
    _ConsultationDemo(
      id: 'demo-1',
      title: 'Amenagement des espaces publics',
      dateLabel: 'Jusqu\'au 15 juin 2024',
      participationLabel: '1 248 participations',
      badge: 'NOUVEAU',
      icon: Icons.park_rounded,
    ),
    _ConsultationDemo(
      id: 'demo-2',
      title: 'Mobilite et transports de demain',
      dateLabel: 'Jusqu\'au 30 juin 2024',
      participationLabel: '892 participations',
      icon: Icons.directions_bus_rounded,
    ),
    _ConsultationDemo(
      id: 'demo-3',
      title: 'Transition ecologique et environnement',
      dateLabel: 'Jusqu\'au 20 juillet 2024',
      participationLabel: '654 participations',
      icon: Icons.public_rounded,
    ),
  ];

  void _onNav(CitizenNavTab tab) {
    if (tab == CitizenNavTab.opinion) return;

    if (tab == CitizenNavTab.home) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CitizenHomePage(initialSession: widget.initialSession),
        ),
        (route) => route.isFirst,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tab == CitizenNavTab.news
              ? 'Page Actualites a connecter.'
              : 'Page Resultats a connecter.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.initialSession;
    final useLiveData = session != null && session.openPolls.isNotEmpty;

    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CitizenHeader(title: 'Donner mon avis'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    _FilterTabs(
                      selectedIndex: selectedFilter,
                      onChanged: (index) {
                        setState(() => selectedFilter = index);
                      },
                    ),
                    const SizedBox(height: 18),
                    if (selectedFilter == 0)
                      if (useLiveData)
                        ...session.openPolls.map(
                          (poll) => ConsultationCard(
                            title: poll.projectTitle,
                            dateLabel: _formatCloseDate(poll),
                            participationLabel: _participationLabel(poll),
                            badge: _badgeForPoll(poll),
                            illustrationIcon: _iconForPoll(poll),
                            onPressed: () => _openPoll(poll),
                          ),
                        )
                      else
                        ..._fallbackConsultations.map(
                          (consultation) => ConsultationCard(
                            title: consultation.title,
                            dateLabel: consultation.dateLabel,
                            participationLabel: consultation.participationLabel,
                            badge: consultation.badge,
                            illustrationIcon: consultation.icon,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CitizenPollQuestionPage(
                                    title: consultation.title,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                    else
                      const _EmptyState(),
                  ],
                ),
              ),
            ),
            CitizenBottomNav(
              activeTab: CitizenNavTab.opinion,
              onTabSelected: _onNav,
            ),
          ],
        ),
      ),
    );
  }

  void _openPoll(PollModel poll) {
    final session = widget.initialSession;
    final code = session?.accessCode;

    if (code != null && code.isNotEmpty) {
      final routeCode = Uri.encodeComponent(code);
      final routePollId = Uri.encodeQueryComponent(poll.id);
      Navigator.of(context).pushNamed('/vote/$routeCode?poll=$routePollId');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CitizenPollQuestionPage(
          title: poll.projectTitle,
          pollId: poll.id,
        ),
      ),
    );
  }

  String _formatCloseDate(PollModel poll) {
    final raw = poll.closeDate.trim();
    if (raw.isEmpty) {
      return 'Date de cloture a confirmer';
    }

    final date = DateTime.tryParse(raw);
    if (date == null) {
      return 'Jusqu\'au $raw';
    }

    const months = [
      'janvier',
      'fevrier',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'aout',
      'septembre',
      'octobre',
      'novembre',
      'decembre',
    ];
    final month = months[date.month - 1];
    return 'Jusqu\'au ${date.day} $month ${date.year}';
  }

  String _participationLabel(PollModel poll) {
    final count = poll.totalVoted;
    if (count <= 1) {
      return '$count participation';
    }
    return '$count participations';
  }

  String? _badgeForPoll(PollModel poll) {
    if (poll.totalVoted == 0) {
      return 'NOUVEAU';
    }
    return null;
  }

  IconData _iconForPoll(PollModel poll) {
    final lower = '${poll.projectTitle} ${poll.question}'.toLowerCase();
    if (lower.contains('transport') || lower.contains('mobilite')) {
      return Icons.directions_bus_rounded;
    }
    if (lower.contains('ecolog') || lower.contains('environ')) {
      return Icons.public_rounded;
    }
    if (lower.contains('parc') || lower.contains('espace')) {
      return Icons.park_rounded;
    }
    return Icons.forum_rounded;
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['En cours', 'A venir', 'Termines'];

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CitizenDesignTokens.lightBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? CitizenDesignTokens.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : CitizenDesignTokens.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: CitizenDesignTokens.cardDecoration,
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: CitizenDesignTokens.primaryBlue,
            size: 44,
          ),
          SizedBox(height: 12),
          Text(
            'Aucune consultation en cours pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CitizenDesignTokens.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Revenez bientot pour donner votre avis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CitizenDesignTokens.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationDemo {
  const _ConsultationDemo({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.participationLabel,
    required this.icon,
    this.badge,
  });

  final String id;
  final String title;
  final String dateLabel;
  final String participationLabel;
  final String? badge;
  final IconData icon;
}
