import 'package:flutter/material.dart';

import '../public_news_page.dart';
import '../public_results_page.dart';

class CitizenPollQuestionPage extends StatefulWidget {
  const CitizenPollQuestionPage({
    super.key,
    this.title = 'Amenagement des espaces publics',
    this.pollId,
    this.accessCode,
  });

  final String title;
  final String? pollId;
  final String? accessCode;

  @override
  State<CitizenPollQuestionPage> createState() =>
      _CitizenPollQuestionPageState();
}

class _CitizenPollQuestionPageState extends State<CitizenPollQuestionPage> {
  final Set<String> selectedOptions = {
    'Espaces verts et parcs',
    'Eclairage public',
    'Accessibilite PMR',
  };

  bool get canContinue => selectedOptions.isNotEmpty;
  bool get otherSelected => selectedOptions.contains('Autre');

  void _toggleOption(String label) {
    setState(() {
      if (selectedOptions.contains(label)) {
        selectedOptions.remove(label);
      } else {
        selectedOptions.add(label);
      }
    });
  }

  void _submitStep() {
    if (!canContinue) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CitizenQuestionStepBridgePage(title: widget.title),
      ),
    );
  }

  void _onNav(CitizenNavTab tab) {
    if (tab == CitizenNavTab.opinion) {
      Navigator.of(context).pushReplacementNamed(
        '/citizen/consultations',
      );
      return;
    }

    if (tab == CitizenNavTab.home) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/citizen/home',
        (route) => route.isFirst,
      );
      return;
    }

    if (tab == CitizenNavTab.news) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublicNewsPage()),
      );
      return;
    }

    if (tab == CitizenNavTab.results) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublicResultsPage()),
      );
      return;
    }

  }

  @override
  Widget build(BuildContext context) {
    final String headerTitle = widget.title == 'Amenagement des espaces publics'
        ? 'Amenagement des\nespaces publics'
        : widget.title;

    return Scaffold(
      backgroundColor: _CitizenColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CitizenHeader(
              title: headerTitle,
              trailing: IconButton(
                tooltip: 'Partager',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partage a connecter.')),
                  );
                },
                icon: const Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Etape 1 sur 6',
                      style: TextStyle(
                        color: _CitizenColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 1 / 6,
                        minHeight: 8,
                        backgroundColor: _CitizenColors.skyBlue,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _CitizenColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _QuestionCard(
                      selectedOptions: selectedOptions,
                      otherSelected: otherSelected,
                      canContinue: canContinue,
                      onToggle: _toggleOption,
                      onContinue: _submitStep,
                    ),
                  ],
                ),
              ),
            ),
            _CitizenBottomNav(
              activeTab: CitizenNavTab.opinion,
              onTabSelected: _onNav,
            ),
          ],
        ),
      ),
    );
  }
}

class _CitizenQuestionStepBridgePage extends StatelessWidget {
  const _CitizenQuestionStepBridgePage({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CitizenColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              _CitizenHeader(
                title: 'Reponse\nenregistree',
                trailing: IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _CitizenColors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _CitizenColors.cardBorder),
                    boxShadow: _CitizenColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: const BoxDecoration(
                          color: _CitizenColors.skyBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: _CitizenColors.primaryBlue,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Votre reponse a bien ete enregistree localement.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _CitizenColors.textDark,
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'La suite du questionnaire pour "$title" sera branchee dans une prochaine etape.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _CitizenColors.textMuted,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _YellowContinueButton(
                        enabled: true,
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/citizen/consultations',
                            (route) => route.isFirst,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/citizen/home',
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text(
                          'Retour a l\'accueil citoyen',
                          style: TextStyle(
                            color: _CitizenColors.deepBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _CitizenBottomNav(
                activeTab: CitizenNavTab.opinion,
                onTabSelected: (tab) {
                  if (tab == CitizenNavTab.opinion) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/citizen/consultations',
                      (route) => route.isFirst,
                    );
                    return;
                  }
                  if (tab == CitizenNavTab.home) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/citizen/home',
                      (route) => route.isFirst,
                    );
                    return;
                  }
                  if (tab == CitizenNavTab.news) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PublicNewsPage()),
                    );
                    return;
                  }
                  if (tab == CitizenNavTab.results) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PublicResultsPage(),
                      ),
                    );
                    return;
                  }
                },
              ),
            ],
          ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 54),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.selectedOptions,
    required this.otherSelected,
    required this.canContinue,
    required this.onToggle,
    required this.onContinue,
  });

  final Set<String> selectedOptions;
  final bool otherSelected;
  final bool canContinue;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _CitizenColors.cardBorder),
        boxShadow: _CitizenColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Quels sont les amenagements\n'
            'que vous jugez prioritaires dans\n'
            'votre commune ?',
            style: TextStyle(
              color: _CitizenColors.textDark,
              fontSize: 18,
              height: 1.22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Vous pouvez choisir plusieurs reponses',
            style: TextStyle(
              color: _CitizenColors.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _QuestionOptionTile(
            label: 'Espaces verts et parcs',
            icon: Icons.park_rounded,
            selected: selectedOptions.contains('Espaces verts et parcs'),
            onTap: () => onToggle('Espaces verts et parcs'),
          ),
          _QuestionOptionTile(
            label: 'Eclairage public',
            icon: Icons.lightbulb_outline_rounded,
            selected: selectedOptions.contains('Eclairage public'),
            onTap: () => onToggle('Eclairage public'),
          ),
          _QuestionOptionTile(
            label: 'Aires de jeux',
            icon: Icons.sports_esports_rounded,
            selected: selectedOptions.contains('Aires de jeux'),
            onTap: () => onToggle('Aires de jeux'),
          ),
          _QuestionOptionTile(
            label: 'Accessibilite PMR',
            icon: Icons.accessible_forward_rounded,
            selected: selectedOptions.contains('Accessibilite PMR'),
            onTap: () => onToggle('Accessibilite PMR'),
          ),
          _QuestionOptionTile(
            label: 'Autre',
            icon: Icons.more_horiz_rounded,
            selected: selectedOptions.contains('Autre'),
            onTap: () => onToggle('Autre'),
          ),
          if (otherSelected) ...[
            const SizedBox(height: 2),
            TextField(
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Precisez votre reponse',
                hintStyle: const TextStyle(
                  color: _CitizenColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: _CitizenColors.lightBlue,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _CitizenColors.cardBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _CitizenColors.cardBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _CitizenColors.primaryBlue,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _YellowContinueButton(
            enabled: canContinue,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _QuestionOptionTile extends StatelessWidget {
  const _QuestionOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _CitizenColors.lightBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _CitizenColors.primaryBlue
                  : _CitizenColors.cardBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: _CitizenColors.skyBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _CitizenColors.primaryBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _CitizenColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? _CitizenColors.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: selected
                        ? _CitizenColors.primaryBlue
                        : _CitizenColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YellowContinueButton extends StatelessWidget {
  const _YellowContinueButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: 'Suivant',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Ink(
              height: 50,
              decoration: BoxDecoration(
                color: enabled
                    ? _CitizenColors.yellowStrong
                    : _CitizenColors.cardBorder,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Suivant',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _CitizenColors.deepBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: _CitizenColors.deepBlue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum CitizenNavTab {
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

  final CitizenNavTab activeTab;
  final ValueChanged<CitizenNavTab> onTabSelected;

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
            tab: CitizenNavTab.home,
            activeTab: activeTab,
            icon: Icons.home_rounded,
            label: 'Accueil',
            onTap: onTabSelected,
          ),
          _BottomNavItem(
            tab: CitizenNavTab.news,
            activeTab: activeTab,
            icon: Icons.calendar_month_rounded,
            label: 'Actualites',
            onTap: onTabSelected,
          ),
          _BottomNavItem(
            tab: CitizenNavTab.opinion,
            activeTab: activeTab,
            icon: Icons.how_to_vote_rounded,
            label: 'Donner mon avis',
            onTap: onTabSelected,
          ),
          _BottomNavItem(
            tab: CitizenNavTab.results,
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

  final CitizenNavTab tab;
  final CitizenNavTab activeTab;
  final IconData icon;
  final String label;
  final ValueChanged<CitizenNavTab> onTap;

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
