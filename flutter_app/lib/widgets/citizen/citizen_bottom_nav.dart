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
        'session':
            session ?? CitizenPublicAccessService.instance.currentSession,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return SafeArea(
          top: false,
          child: SizedBox(
            height: compact ? 82 : 90,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 16,
                4,
                compact ? 10 : 16,
                8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF0F4F7)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18002F4A),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 2 : 8,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    _NavItem(
                      tab: CitizenNavTab.home,
                      activeTab: activeTab,
                      icon: Icons.home_rounded,
                      label: 'Accueil',
                      compact: compact,
                      onTap: onTabSelected,
                    ),
                    _NavItem(
                      tab: CitizenNavTab.news,
                      activeTab: activeTab,
                      icon: Icons.article_outlined,
                      label: 'Actualités',
                      compact: compact,
                      onTap: onTabSelected,
                    ),
                    _NavItem(
                      tab: CitizenNavTab.opinion,
                      activeTab: activeTab,
                      icon: Icons.edit_outlined,
                      label: 'Donner mon avis',
                      compact: compact,
                      onTap: onTabSelected,
                    ),
                    _NavItem(
                      tab: CitizenNavTab.results,
                      activeTab: activeTab,
                      icon: Icons.bar_chart_rounded,
                      label: 'Résultats',
                      compact: compact,
                      onTap: onTabSelected,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.activeTab,
    required this.icon,
    required this.label,
    required this.compact,
    required this.onTap,
  });

  final CitizenNavTab tab;
  final CitizenNavTab activeTab;
  final IconData icon;
  final String label;
  final bool compact;
  final ValueChanged<CitizenNavTab> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = tab == activeTab;
    final color = isActive
        ? CitizenDesignTokens.primaryBlue
        : const Color(0xFF53657A);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: compact ? 24 : 27,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: compact ? 9.1 : 10.5,
                    height: 1,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: CitizenDesignTokens.motionFast,
                  width: isActive ? (compact ? 30 : 36) : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: CitizenDesignTokens.primaryBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
