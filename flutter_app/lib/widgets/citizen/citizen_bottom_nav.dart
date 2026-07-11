import 'package:flutter/material.dart';

import '../../theme/citizen_design_tokens.dart';

enum CitizenNavTab {
  home,
  news,
  opinion,
  results,
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
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
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
            icon: Icons.calendar_month_rounded,
            label: 'Actualités',
            onTap: onTabSelected,
          ),
          _NavItem(
            tab: CitizenNavTab.opinion,
            activeTab: activeTab,
            icon: Icons.how_to_vote_rounded,
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
                color:
                    isActive ? CitizenDesignTokens.skyBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive
                    ? CitizenDesignTokens.deepBlue
                    : CitizenDesignTokens.textDark.withValues(alpha: 0.75),
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
                    ? CitizenDesignTokens.deepBlue
                    : CitizenDesignTokens.textDark.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
