import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/citizen_public_access_service.dart';
import '../services/new_poll_badge_service.dart';

enum PublicTab { home, news, vote, results }

class PublicBottomNav extends StatefulWidget {
  const PublicBottomNav({
    required this.currentTab,
    this.backgroundColor = Colors.white,
    this.indicatorColor = const Color(0xFFE7F5FF),
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

  static const _activeColor = Color(0xFF0756B8);
  static const _inactiveColor = Color(0xFF536173);

  @override
  void initState() {
    super.initState();
    _badgeSvc.startListening();
  }

  void _handleTap(BuildContext context, int index) {
    final voteRoute =
        CitizenPublicAccessService.instance.currentSession != null
            ? '/access-citizen'
            : '/donner-mon-avis';
    final routes = <String>['/', '/news', voteRoute, '/results'];
    final targetRoute = routes[index];
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == targetRoute) return;

    Navigator.of(context).pushReplacementNamed(
      targetRoute,
      arguments: const {'disableTransition': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 700;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          height: compact ? 76 : 72,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: widget.backgroundColor.withValues(alpha: 0.98),
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
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
                    indicatorColor: widget.indicatorColor,
                    onTap: () => _handleTap(context, 0),
                  ),
                  _NavItem(
                    icon: Icons.article_outlined,
                    label: 'Actualités',
                    selected: widget.currentTab == PublicTab.news,
                    compact: compact,
                    indicatorColor: widget.indicatorColor,
                    onTap: () => _handleTap(context, 1),
                  ),
                  _NavItem(
                    icon: Icons.edit_square,
                    label: 'Donner mon avis',
                    selected: widget.currentTab == PublicTab.vote,
                    compact: compact,
                    indicatorColor: widget.indicatorColor,
                    showBadge: hasNew,
                    onTap: () => _handleTap(context, 2),
                  ),
                  _NavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Résultats',
                    selected: widget.currentTab == PublicTab.results,
                    compact: compact,
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
    required this.indicatorColor,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final Color indicatorColor;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? _PublicBottomNavState._activeColor
        : _PublicBottomNavState._inactiveColor;
    final iconSize = selected ? 27.0 : 23.0;
    final labelStyle = GoogleFonts.inter(
      fontSize: compact ? 10.5 : 11,
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
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                constraints: BoxConstraints(
                  minWidth: compact ? 68 : 82,
                  maxWidth: compact ? 112 : 130,
                ),
                height: 58,
                decoration: BoxDecoration(
                  color: selected ? indicatorColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWidget,
                    const SizedBox(height: 3),
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
