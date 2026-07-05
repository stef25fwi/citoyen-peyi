import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/new_poll_badge_service.dart';

enum PublicTab { home, news, vote, results }

class PublicBottomNav extends StatefulWidget {
  const PublicBottomNav({
    required this.currentTab,
    this.backgroundColor = Colors.white,
    this.indicatorColor = const Color(0xFFF1F5F9),
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
  static const _activeBackground = Color(0xFFE7F5FF);

  @override
  void initState() {
    super.initState();
    _badgeSvc.startListening();
  }

  void _handleTap(BuildContext context, int index) {
    final routes = <String>['/', '/news', '/access-citizen', '/results'];
    final targetRoute = routes[index];
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == targetRoute) {
      return;
    }

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
      child: Container(
        height: compact ? 58 : 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          border: Border(
            top: BorderSide(
              color: Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: _badgeSvc.hasNew,
          builder: (context, hasNew, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  selected: widget.currentTab == PublicTab.home,
                  compact: compact,
                  onTap: () => _handleTap(context, 0),
                ),
                _NavItem(
                  icon: Icons.article_outlined,
                  label: 'Actualités',
                  selected: widget.currentTab == PublicTab.news,
                  compact: compact,
                  onTap: () => _handleTap(context, 1),
                ),
                _NavItem(
                  icon: Icons.edit_square,
                  label: 'Donner mon avis',
                  selected: widget.currentTab == PublicTab.vote,
                  compact: compact,
                  showBadge: hasNew,
                  onTap: () => _handleTap(context, 2),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Résultats',
                  selected: widget.currentTab == PublicTab.results,
                  compact: compact,
                  onTap: () => _handleTap(context, 3),
                ),
              ],
            );
          },
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
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? _PublicBottomNavState._activeColor
        : _PublicBottomNavState._inactiveColor;
    final iconSize = selected ? 24.0 : 20.0;
    final labelStyle = GoogleFonts.inter(
      fontSize: compact ? 9 : 10.5,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      color: iconColor,
      letterSpacing: -0.1,
    );

    Widget iconWidget = Icon(icon, color: iconColor, size: iconSize);
    if (showBadge) {
      iconWidget = Badge(isLabelVisible: true, child: iconWidget);
    }

    return Expanded(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: selected ? (compact ? 74 : 94) : (compact ? 56 : 72),
              height: selected ? 46 : 42,
              decoration: BoxDecoration(
                color: selected
                    ? _PublicBottomNavState._activeBackground
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(height: 1),
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
    );
  }
}
