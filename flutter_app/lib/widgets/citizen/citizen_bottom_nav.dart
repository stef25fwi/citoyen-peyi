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
        return Container(
          height: compact ? 70 : CitizenDesignTokens.bottomNavHeight,
          padding: EdgeInsets.fromLTRB(
            compact ? 3 : 8,
            compact ? 4 : 6,
            compact ? 3 : 8,
            compact ? 6 : 8,
          ),
          decoration: const BoxDecoration(
            color: CitizenDesignTokens.surface,
            border: Border(
              top: BorderSide(color: CitizenDesignTokens.divider),
            ),
            boxShadow: CitizenDesignTokens.navigationShadow,
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
                icon: Icons.edit_square,
                label: compact ? 'Mon avis' : 'Donner mon avis',
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
    final theme = Theme.of(context);
    final isActive = tab == activeTab;
    final color =
        isActive ? CitizenDesignTokens.deepBlue : CitizenDesignTokens.textMuted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusButton),
          onTap: () => onTap(tab),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: CitizenDesignTokens.motionFast,
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 15,
                  vertical: compact ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? CitizenDesignTokens.skyBlue
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(CitizenDesignTokens.radiusButton),
                  border: isActive
                      ? Border.all(
                          color: CitizenDesignTokens.cardBorder,
                          width: 0.8,
                        )
                      : null,
                ),
                child: Icon(
                  icon,
                  size: compact ? (isActive ? 23 : 21) : (isActive ? 25 : 23),
                  color: color,
                ),
              ),
              SizedBox(height: compact ? 2 : 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: compact ? 9.5 : 10.5,
                  height: 1,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
