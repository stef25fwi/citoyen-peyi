import 'package:flutter/material.dart';

import '../services/citizen_public_access_service.dart';
import '../services/new_poll_badge_service.dart';
import '../theme/citizen_design_tokens.dart';

enum PublicTab { home, news, vote, results }

class PublicBottomNav extends StatefulWidget {
  const PublicBottomNav({
    required this.currentTab,
    this.backgroundColor = CitizenDesignTokens.surface,
    this.indicatorColor = CitizenDesignTokens.skyBlue,
    super.key,
  });

  final PublicTab currentTab;
  final Color backgroundColor;
  final Color indicatorColor;

  @override
  State<PublicBottomNav> createState() => _PublicBottomNavState();
}

class _PublicBottomNavState extends State<PublicBottomNav> {
  final _badgeSvc = NewPollBadgeService.instance;

  @override
  void initState() {
    super.initState();
    _badgeSvc.startListening();
  }

  void _handleTap(BuildContext context, int index) {
    final session = CitizenPublicAccessService.instance.currentSession;
    final connected = session != null;
    final routes = connected
        ? <String>[
            '/citizen/home',
            '/news',
            '/citizen/consultations',
            '/results',
          ]
        : <String>['/', '/news', '/donner-mon-avis', '/results'];
    final targetRoute = routes[index];
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == targetRoute) return;

    Navigator.of(context).pushReplacementNamed(
      targetRoute,
      arguments: {
        'session': session,
        'disableTransition': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    final veryCompact = width < 360;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          height: veryCompact ? 70 : (compact ? 76 : 74),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: veryCompact ? 2 : 6,
            vertical: veryCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: widget.backgroundColor.withValues(alpha: 0.98),
            border: const Border(
              top: BorderSide(
                color: CitizenDesignTokens.divider,
                width: 1,
              ),
            ),
            boxShadow: CitizenDesignTokens.navigationShadow,
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: _badgeSvc.hasNew,
            builder: (context, hasNew, _) {
              return Row(
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Accueil',
                    selected: widget.currentTab == PublicTab.home,
                    compact: compact,
                    veryCompact: veryCompact,
                    indicatorColor: widget.indicatorColor,
                    onTap: () => _handleTap(context, 0),
                  ),
                  _NavItem(
                    icon: Icons.article_outlined,
                    label: 'Actualités',
                    selected: widget.currentTab == PublicTab.news,
                    compact: compact,
                    veryCompact: veryCompact,
                    indicatorColor: widget.indicatorColor,
                    onTap: () => _handleTap(context, 1),
                  ),
                  _NavItem(
                    icon: Icons.edit_square,
                    label: veryCompact ? 'Mon avis' : 'Donner mon avis',
                    selected: widget.currentTab == PublicTab.vote,
                    compact: compact,
                    veryCompact: veryCompact,
                    indicatorColor: widget.indicatorColor,
                    showBadge: hasNew,
                    onTap: () => _handleTap(context, 2),
                  ),
                  _NavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Résultats',
                    selected: widget.currentTab == PublicTab.results,
                    compact: compact,
                    veryCompact: veryCompact,
                    indicatorColor: widget.indicatorColor,
                    onTap: () => _handleTap(context, 3),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.veryCompact,
    required this.indicatorColor,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final bool veryCompact;
  final Color indicatorColor;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = selected
        ? CitizenDesignTokens.deepBlue
        : CitizenDesignTokens.textMuted;
    final iconSize = veryCompact
        ? (selected ? 23.0 : 21.0)
        : (selected ? 26.0 : 23.0);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: veryCompact ? 9.5 : (compact ? 10.5 : 11),
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      color: iconColor,
      letterSpacing: -0.15,
      height: 1.05,
    );

    Widget iconWidget = Icon(icon, color: iconColor, size: iconSize);
    if (showBadge) {
      iconWidget = Badge(isLabelVisible: true, child: iconWidget);
    }

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(CitizenDesignTokens.radiusButton),
            onTap: onTap,
            child: Center(
              child: AnimatedContainer(
                duration: CitizenDesignTokens.motionFast,
                curve: Curves.easeOutCubic,
                constraints: BoxConstraints(
                  minWidth: veryCompact ? 58 : (compact ? 68 : 82),
                  maxWidth: veryCompact ? 90 : (compact ? 112 : 130),
                ),
                height: veryCompact ? 54 : 58,
                decoration: BoxDecoration(
                  color: selected ? indicatorColor : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(CitizenDesignTokens.radiusButton),
                  border: selected
                      ? Border.all(
                          color: CitizenDesignTokens.cardBorder,
                          width: 0.8,
                        )
                      : null,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: veryCompact ? 3 : 5,
                  vertical: 5,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWidget,
                    SizedBox(height: veryCompact ? 2 : 3),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
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