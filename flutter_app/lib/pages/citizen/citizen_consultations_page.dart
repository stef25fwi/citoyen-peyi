import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/citizen_public_access_service.dart';
import '../public_news_page.dart';
import '../public_results_page.dart';
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

  final List<_ConsultationItem> consultations = const [
    _ConsultationItem(
      title: 'Aménagement des espaces publics',
      displayTitle: 'Aménagement des espaces\npublics',
      dateLabel: 'Jusqu’au 15 juin 2024',
      participationLabel: '1 248 participations',
      badge: 'NOUVEAU',
      icon: Icons.park_rounded,
      asset: 'assets/citoyen_peyi/cp_illustration_public_spaces.svg',
    ),
    _ConsultationItem(
      title: 'Mobilité et transports de demain',
      displayTitle: 'Mobilité et transports\nde demain',
      dateLabel: 'Jusqu’au 30 juin 2024',
      participationLabel: '892 participations',
      icon: Icons.directions_bus_rounded,
      asset: 'assets/citoyen_peyi/cp_illustration_mobility_bus.svg',
    ),
    _ConsultationItem(
      title: 'Transition écologique et environnement',
      displayTitle: 'Transition écologique\net environnement',
      dateLabel: 'Jusqu’au 20 juillet 2024',
      participationLabel: '654 participations',
      icon: Icons.public_rounded,
      asset: 'assets/citoyen_peyi/cp_illustration_ecology_transition.svg',
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
    if (session == null || session.openPolls.isEmpty) {
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
            asset: _assetForPoll(poll.projectTitle, poll.question),
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
      final nextLength =
          currentLength == 0 ? word.length : currentLength + 1 + word.length;
      if (nextLength > 24 && currentLength > 0) {
        buffer.write('\n');
        buffer.write(word);
        currentLength = word.length;
      } else {
        if (currentLength > 0) buffer.write(' ');
        buffer.write(word);
        currentLength = nextLength;
      }
    }
    return buffer.toString();
  }

  String _formatCloseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Date de clôture à confirmer';

    final date = DateTime.tryParse(trimmed);
    if (date == null) return 'Jusqu’au $trimmed';

    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return 'Jusqu’au ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _participationLabel(int totalVoted) {
    return totalVoted <= 1
        ? '$totalVoted participation'
        : '$totalVoted participations';
  }

  IconData _iconForPoll(String title, String question) {
    final lower = '$title $question'.toLowerCase();
    if (lower.contains('transport') || lower.contains('mobilité')) {
      return Icons.directions_bus_rounded;
    }
    if (lower.contains('écolog') || lower.contains('ecolog') || lower.contains('environ')) {
      return Icons.public_rounded;
    }
    if (lower.contains('parc') || lower.contains('espace') || lower.contains('aménagement') || lower.contains('amenagement')) {
      return Icons.park_rounded;
    }
    return Icons.forum_rounded;
  }

  String? _assetForPoll(String title, String question) {
    final lower = '$title $question'.toLowerCase();
    if (lower.contains('transport') || lower.contains('mobilité')) {
      return 'assets/citoyen_peyi/cp_illustration_mobility_bus.svg';
    }
    if (lower.contains('écolog') || lower.contains('ecolog') || lower.contains('environ')) {
      return 'assets/citoyen_peyi/cp_illustration_ecology_transition.svg';
    }
    if (lower.contains('parc') || lower.contains('espace') || lower.contains('aménagement') || lower.contains('amenagement')) {
      return 'assets/citoyen_peyi/cp_illustration_public_spaces.svg';
    }
    return null;
  }

  void _onBottomNav(_CitizenNavTab tab) {
    if (tab == _CitizenNavTab.opinion) return;

    if (tab == _CitizenNavTab.home) {
      Navigator.of(context).pushReplacementNamed(
        '/citizen/home',
        arguments: {'session': widget.initialSession},
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
    }
  }

  Future<void> _logoutCitizen() async {
    await CitizenPublicAccessService.instance.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/access', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedConsultations = _resolvedConsultations();

    return Scaffold(
      backgroundColor: _CitizenColors.background,
      body: _MobileFrame(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _CitizenHeader(
                title: 'Donner mon avis',
                trailing: IconButton(
                  tooltip: 'Se déconnecter',
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    children: [
                      _FilterTabs(
                        selectedIndex: selectedFilter,
                        onChanged: (index) {
                          setState(() => selectedFilter = index);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedFilter == 0)
                        if (resolvedConsultations.isEmpty)
                          const _EmptyState(
                            message:
                                'Aucune consultation en cours pour le moment.',
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
                              ? 'Aucune consultation à venir pour le moment.'
                              : 'Aucune consultation terminée à afficher.',
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
      ),
    );
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

class _CitizenColors {
  const _CitizenColors._();

  static const Color primaryBlue = Color(0xFF0075C9);
  static const Color deepBlue = Color(0xFF005CA8);
  static const Color skyBlue = Color(0xFFEAF8FF);
  static const Color lightBlue = Color(0xFFF2FAFF);
  static const Color yellowStrong = Color(0xFFFFDA29);
  static const Color textDark = Color(0xFF143B5A);
  static const Color textMuted = Color(0xFF607A94);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE3EEF6);
  static const Color background = Color(0xFFF6FCFF);
  static const Color badgeBlue = Color(0xFF28C7F3);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, deepBlue],
  );

  static List<BoxShadow> softShadow = const [
    BoxShadow(
      color: Color(0x1A0075C9),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}

class _CitizenHeader extends StatelessWidget {
  const _CitizenHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: _CitizenColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 54),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null)
                Align(alignment: Alignment.centerRight, child: trailing!),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['En cours', 'À venir', 'Terminés'];

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _CitizenColors.lightBlue,
        borderRadius: BorderRadius.circular(999),
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
                  color: selected ? _CitizenColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
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
  const _ConsultationCard({required this.consultation, required this.onPressed});

  final _ConsultationItem consultation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: BorderRadius.circular(18),
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
              _IllustrationBox(icon: consultation.icon, asset: consultation.asset),
            ],
          ),
          const SizedBox(height: 12),
          _YellowActionButton(label: 'Je donne mon avis', onPressed: onPressed),
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
            fontSize: 16.5,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _MetaRow(icon: Icons.calendar_month_rounded, text: dateLabel),
        const SizedBox(height: 5),
        _MetaRow(icon: Icons.groups_rounded, text: participationLabel),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _CitizenColors.textMuted),
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
  const _IllustrationBox({required this.icon, this.asset});

  final IconData icon;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final assetPath = asset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 96,
        height: 84,
        child: assetPath == null
            ? Container(
                color: _CitizenColors.skyBlue,
                child: Icon(icon, size: 48, color: _CitizenColors.primaryBlue),
              )
            : SvgPicture.asset(assetPath, fit: BoxFit.cover),
      ),
    );
  }
}

class _YellowActionButton extends StatelessWidget {
  const _YellowActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            color: _CitizenColors.yellowStrong,
            borderRadius: BorderRadius.circular(10),
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
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 15, color: _CitizenColors.deepBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CitizenNavTab { home, news, opinion, results }

class _CitizenBottomNav extends StatelessWidget {
  const _CitizenBottomNav({required this.activeTab, required this.onTabSelected});

  final _CitizenNavTab activeTab;
  final ValueChanged<_CitizenNavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0075C9),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          _BottomNavItem(tab: _CitizenNavTab.home, activeTab: activeTab, icon: Icons.home_rounded, label: 'Accueil', onTap: onTabSelected),
          _BottomNavItem(tab: _CitizenNavTab.news, activeTab: activeTab, icon: Icons.calendar_month_rounded, label: 'Actualités', onTap: onTabSelected),
          _BottomNavItem(tab: _CitizenNavTab.opinion, activeTab: activeTab, icon: Icons.how_to_vote_rounded, label: 'Donner mon avis', onTap: onTabSelected),
          _BottomNavItem(tab: _CitizenNavTab.results, activeTab: activeTab, icon: Icons.bar_chart_rounded, label: 'Résultats', onTap: onTabSelected),
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
    final isActive = tab == activeTab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onTap(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? _CitizenColors.skyBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 22, color: isActive ? _CitizenColors.primaryBlue : _CitizenColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? _CitizenColors.primaryBlue : _CitizenColors.textMuted,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CitizenColors.cardBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _CitizenColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
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
    this.asset,
    this.badge,
    this.pollId,
  });

  final String title;
  final String displayTitle;
  final String dateLabel;
  final String participationLabel;
  final IconData icon;
  final String? asset;
  final String? badge;
  final String? pollId;
}
