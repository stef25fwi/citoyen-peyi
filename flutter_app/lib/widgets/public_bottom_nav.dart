import 'package:flutter/material.dart';

import '../services/new_poll_badge_service.dart';

enum PublicTab { home, news, vote, results }

class PublicBottomNav extends StatefulWidget {
  const PublicBottomNav({
    required this.currentTab,
    super.key,
  });

  final PublicTab currentTab;

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
    final baseTheme = Theme.of(context);

    return Material(
      color: const Color(0xFFEAF7FF),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
      elevation: 10,
      shadowColor: Colors.black38,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: baseTheme.copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            overlayColor:
                const WidgetStatePropertyAll<Color>(Colors.transparent),
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFFCAE9FB),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: selected ? 26 : 22,
                color: selected
                    ? const Color(0xFF005098)
                    : const Color(0xFF1A2E50),
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF005098)
                    : const Color(0xFF1A2E50),
              );
            }),
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: _badgeSvc.hasNew,
            builder: (context, hasNew, _) {
              return NavigationBar(
                height: 74,
                selectedIndex: widget.currentTab.index,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (index) => _handleTap(context, index),
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_rounded),
                    selectedIcon: Icon(Icons.home_filled),
                    label: 'Accueil',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.newspaper_outlined),
                    selectedIcon: Icon(Icons.newspaper_rounded),
                    label: 'Actualites',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: hasNew,
                      child: const Icon(Icons.how_to_vote_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: hasNew,
                      child: const Icon(Icons.how_to_vote_rounded),
                    ),
                    label: 'Donner mon avis',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: 'Resultats',
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
