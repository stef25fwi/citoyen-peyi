import 'package:flutter/material.dart';

import '../../services/citizen_public_access_service.dart';
import '../../theme/citizen_design_tokens.dart';

enum CitizenNavTab {
  home,
  news,
  opinion,
  results,
}

/// Navigation commune à tout le parcours citoyen connecté.
///
/// Les quatre onglets racines utilisent systématiquement des routes nommées
/// stables. L'écran de bienvenue n'est jamais utilisé comme destination d'un
/// onglet : il reste uniquement disponible pour un éventuel onboarding.
class CitizenNavigation {
  const CitizenNavigation._();

  static String routeFor(CitizenNavTab tab) {
    switch (tab) {
      case CitizenNavTab.home:
        return '/citizen/home';
      case CitizenNavTab.news:
        return '/news';
      case CitizenNavTab.opinion:
        return '/citizen/consultations';
      case CitizenNavTab.results:
        return '/results';
    }
  }

  static void open(
    BuildContext context,
    CitizenNavTab tab, {
    CitizenPublicAccessSession? session,
  }) {
    final target = routeFor(tab);
    final current = ModalRoute.of(context)?.settings.name;
    if (current == target) return;

    Navigator.of(context).pushReplacementNamed(
      target,
      arguments: {
        'session': session ?? CitizenPublicAccessService.instance.currentSession,
        'disableTransition': true,
      },
    );
  }
}

class CitizenBottomNav extends StatelessWidget {
  const CitizenBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  final CitizenNavTab activeTab;
  final ValueChanged<CitizenNavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CitizenDesignTokens.bottomNavHeight,
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
      decoration: const BoxDecoration(
        color: CitizenDesignTokens.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A005A9C),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            tab: CitizenNavTab.home,
            activeTab: activeTab,
            icon: Icons.home_rounded,
            label: 'Accueil',
            onTap: onTabSelected,
          ),
          _NavItem(
            tab: CitizenNavTab.news,
            activeTab: activeTab,
            icon: Icons.article_outlined,
            label: 'Actualités',
            onTap: onTabSelected,
          ),
          _NavItem(
            tab: CitizenNavTab.opinion,
            activeTab: activeTab,
            icon: Icons.edit_square,
            label: 'Donner mon avis',
            onTap: onTabSelected,
          ),
          _NavItem(
            tab: CitizenNavTab.results,
            activeTab: activeTab,
            icon: Icons.bar_chart_rounded,
            label: 'Résultats',
            onTap: onTabSelected,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    final isActive = tab == activeTab;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onTap(tab),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? CitizenDesignTokens.skyBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  icon,
                  size: isActive ? 25 : 23,
                  color: isActive
                      ? CitizenDesignTokens.deepBlue
                      : CitizenDesignTokens.textDark.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? CitizenDesignTokens.deepBlue
                      : CitizenDesignTokens.textDark.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
