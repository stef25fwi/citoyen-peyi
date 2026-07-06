import 'package:flutter/material.dart';

import '../../services/citizen_public_access_service.dart';
import 'citizen_home_page.dart';
import 'citizen_poll_question_page.dart';
import '../public_news_page.dart';
import '../public_results_page.dart';

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

  final List<_ConsultationItem> consultations = const [
    _ConsultationItem(
      title: 'Amenagement des espaces publics',
      displayTitle: 'Amenagement des espaces\npublics',
      dateLabel: 'Jusqu\'au 15 juin 2024',
      participationLabel: '1 248 participations',
      badge: 'NOUVEAU',
      icon: Icons.park_rounded,
    ),
    _ConsultationItem(
      title: 'Mobilite et transports de demain',
      displayTitle: 'Mobilite et transports\nde demain',
      dateLabel: 'Jusqu\'au 30 juin 2024',
      participationLabel: '892 participations',
      icon: Icons.directions_bus_rounded,
    ),
    _ConsultationItem(
      title: 'Transition ecologique et environnement',
      displayTitle: 'Transition ecologique\net environnement',
      dateLabel: 'Jusqu\'au 20 juillet 2024',
      participationLabel: '654 participations',
      icon: Icons.public_rounded,
    ),
  ];

  void _openConsultation(_ConsultationItem consultation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CitizenPollQuestionPage(
          title: consultation.title,
          pollId: consultation.pollId,
          accessCode: widget.initialSession?.accessCode,
        ),
      ),
    );
  }

  List<_ConsultationItem> _resolvedConsultations() {
    final session = widget.initialSession;
    if (session == null) {
      return consultations;
    }

    return session.openPolls
        .map(
          (poll) => _ConsultationItem(
            title: poll.projectTitle,
            displayTitle: _displayTitleFor(poll.projectTitle),
            dateLabel: _formatCloseDate(poll.closeDate),
            participationLabel: _participationLabel(poll.totalVoted),
            badge: poll.totalVoted == 0 ? 'NOUVEAU' : null,
            icon: _iconForPoll(poll.projectTitle, poll.question),
            pollId: poll.id,
          ),
        )
        .toList(growable: false);
  }

  String _displayTitleFor(String title) {
    final normalized = title.trim();
    if (normalized.length <= 26 || !normalized.contains(' ')) {
      return normalized;
    }

    final words = normalized.split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    var currentLength = 0;
    for (final word in words) {
      final nextLength = currentLength == 0 ? word.length : currentLength + 1 + word.length;
      if (nextLength > 24 && currentLength > 0) {
        buffer.write('\n');
        buffer.write(word);
        currentLength = word.length;
      } else {
        if (currentLength > 0) {
          buffer.write(' ');
        }
        buffer.write(word);
        currentLength = nextLength;
      }
    }
    return buffer.toString();
  }

  String _formatCloseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Date de cloture a confirmer';
    }

    final date = DateTime.tryParse(trimmed);
    if (date == null) {
      return 'Jusqu\'au $trimmed';
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
    return 'Jusqu\'au ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _participationLabel(int totalVoted) {
    if (totalVoted <= 1) {
      return '$totalVoted participation';
    }
    return '$totalVoted participations';
  }

  IconData _iconForPoll(String title, String question) {
    final lower = '$title $question'.toLowerCase();
    if (lower.contains('transport') || lower.contains('mobilite')) {
      return Icons.directions_bus_rounded;
    }
    if (lower.contains('ecolog') || lower.contains('environ')) {
      return Icons.public_rounded;
    }
    if (lower.contains('parc') || lower.contains('espace') || lower.contains('amenagement')) {
      return Icons.park_rounded;
    }
    return Icons.forum_rounded;
  }

  void _onBottomNav(_CitizenNavTab tab) {
    if (tab == _CitizenNavTab.opinion) return;

    if (tab == _CitizenNavTab.home) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CitizenHomePage(initialSession: widget.initialSession),
        ),
      );
      return;
    }

    if (tab == _CitizenNavTab.news) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublicNewsPage()),
      );
      return;
    }

    if (tab == _CitizenNavTab.results) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublicResultsPage()),
      );
      return;
    }

  }

  Future<void> _logoutCitizen() async {
    await CitizenPublicAccessService.instance.clearSession();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/access',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedConsultations = _resolvedConsultations();

    return Scaffold(
      backgroundColor: _CitizenColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CitizenHeader(
              title: 'Donner mon avis',
              trailing: IconButton(
                tooltip: 'Se deconnecter',
                onPressed: _logoutCitizen,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                      if (resolvedConsultations.isEmpty)
                        const _EmptyState(
                          message: 'Aucune consultation en cours pour le moment.',
                        )
                      else
                        ...resolvedConsultations.map(
                          (consultation) => _ConsultationCard(
                            consultation: consultation,
                            onPressed: () => _openConsultation(consultation),
                          ),
                        )
                    else
                      _EmptyState(
                        message: selectedFilter == 1
                            ? 'Aucune consultation a venir pour le moment.'
                            : 'Aucune consultation terminee a afficher.',
                      ),
                  ],
                ),
              ),
            ),
            _CitizenBottomNav(
              activeTab: _CitizenNavTab.opinion,
              onTabSelected: _onBottomNav,
            ),
          ],
        ),
      ),
    );
  }
}

class _CitizenColors {
  const _CitizenColors._();

  static const Color primaryBlue = Color(0xFF0077C8);
  static const Color deepBlue = Color(0xFF005A9C);
  static const Color skyBlue = Color(0xFFDFF5FF);
  static const Color lightBlue = Color(0xFFF2FAFF);
  static const Color yellowStrong = Color(0xFFFFD21F);
  static const Color textDark = Color(0xFF0B2F4A);
  static const Color textMuted = Color(0xFF6B7C8F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE4F1FA);
  static const Color background = Color(0xFFF5FBFF);
  static const Color badgeBlue = Color(0xFF28C7F3);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryBlue,
      deepBlue,
    ],
  );

  static List<BoxShadow> softShadow = [
    const BoxShadow(
      color: Color(0x1A005A9C),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

class _CitizenHeader extends StatelessWidget {
  const _CitizenHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: _CitizenColors.headerGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Retour',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (trailing != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
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
        color: _CitizenColors.lightBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final bool selected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? _CitizenColors.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: selected ? Colors.white : _CitizenColors.textDark,
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

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({
    required this.consultation,
    required this.onPressed,
  });

  final _ConsultationItem consultation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _CitizenColors.cardBorder),
        boxShadow: _CitizenColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ConsultationText(
                  badge: consultation.badge,
                  title: consultation.displayTitle,
                  dateLabel: consultation.dateLabel,
                  participationLabel: consultation.participationLabel,
                ),
              ),
              const SizedBox(width: 12),
              _IllustrationBox(icon: consultation.icon),
            ],
          ),
          const SizedBox(height: 12),
          _YellowActionButton(
            label: 'Je donne mon avis',
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _ConsultationText extends StatelessWidget {
  const _ConsultationText({
    required this.title,
    required this.dateLabel,
    required this.participationLabel,
    this.badge,
  });

  final String title;
  final String dateLabel;
  final String participationLabel;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _CitizenColors.badgeBlue,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _CitizenColors.textDark,
            fontSize: 17,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _MetaRow(
          icon: Icons.calendar_month_rounded,
          text: dateLabel,
        ),
        const SizedBox(height: 5),
        _MetaRow(
          icon: Icons.groups_rounded,
          text: participationLabel,
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: _CitizenColors.textMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _CitizenColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _IllustrationBox extends StatelessWidget {
  const _IllustrationBox({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: _CitizenColors.skyBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            right: 12,
            child: Icon(
              Icons.cloud_rounded,
              size: 22,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              width: 24,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Icon(
            icon,
            size: 48,
            color: _CitizenColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _YellowActionButton extends StatelessWidget {
  const _YellowActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onPressed,
          child: Ink(
            height: 43,
            decoration: BoxDecoration(
              color: _CitizenColors.yellowStrong,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _CitizenColors.deepBlue,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: _CitizenColors.deepBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CitizenNavTab {
  home,
  news,
  opinion,
  results,
}

class _CitizenBottomNav extends StatelessWidget {
  const _CitizenBottomNav({
    required this.activeTab,
    required this.onTabSelected,
  });

  final _CitizenNavTab activeTab;
  final ValueChanged<_CitizenNavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A005A9C),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          _BottomNavItem(
            tab: _CitizenNavTab.home,
            activeTab: activeTab,
            icon: Icons.home_rounded,
            label: 'Accueil',
            onTap: onTabSelected,
          ),
          _BottomNavItem(
            tab: _CitizenNavTab.news,
            activeTab: activeTab,
            icon: Icons.calendar_month_rounded,
            label: 'Actualites',
            onTap: onTabSelected,
          ),
          _BottomNavItem(
            tab: _CitizenNavTab.opinion,
            activeTab: activeTab,
            icon: Icons.how_to_vote_rounded,
            label: 'Donner mon avis',
            onTap: onTabSelected,
          ),
          _BottomNavItem(
            tab: _CitizenNavTab.results,
            activeTab: activeTab,
            icon: Icons.bar_chart_rounded,
            label: 'Resultats',
            onTap: onTabSelected,
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.tab,
    required this.activeTab,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final _CitizenNavTab tab;
  final _CitizenNavTab activeTab;
  final IconData icon;
  final String label;
  final ValueChanged<_CitizenNavTab> onTap;

  @override
  Widget build(BuildContext context) {
    final bool isActive = tab == activeTab;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onTap(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? _CitizenColors.skyBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive
                    ? _CitizenColors.deepBlue
                    : _CitizenColors.textDark.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive
                    ? _CitizenColors.deepBlue
                    : _CitizenColors.textDark.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _CitizenColors.cardBorder),
        boxShadow: _CitizenColors.softShadow,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: _CitizenColors.primaryBlue,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _CitizenColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationItem {
  const _ConsultationItem({
    required this.title,
    required this.displayTitle,
    required this.dateLabel,
    required this.participationLabel,
    required this.icon,
    this.pollId,
    this.badge,
  });

  final String title;
  final String displayTitle;
  final String dateLabel;
  final String participationLabel;
  final IconData icon;
  final String? pollId;
  final String? badge;
}
