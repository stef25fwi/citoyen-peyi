import 'package:flutter/material.dart';

enum PublicTab { home, vote, results, news, profile }

class PublicBottomNav extends StatelessWidget {
  const PublicBottomNav({
    required this.currentTab,
    super.key,
  });

  final PublicTab currentTab;

  void _handleTap(BuildContext context, int index) {
    final routes = <String>['/', '/access', '/results', '/news', '/profile'];
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

    return Theme(
      data: baseTheme.copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: NavigationBarTheme(
        data: const NavigationBarThemeData(
          overlayColor: MaterialStatePropertyAll<Color>(Colors.transparent),
        ),
        child: NavigationBar(
          height: 78,
          selectedIndex: currentTab.index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => _handleTap(context, index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              selectedIcon: Icon(Icons.home_filled),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.how_to_vote_outlined),
              selectedIcon: Icon(Icons.how_to_vote_rounded),
              label: 'Donner mon avis',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Resultats',
            ),
            NavigationDestination(
              icon: Icon(Icons.newspaper_outlined),
              selectedIcon: Icon(Icons.newspaper_rounded),
              label: 'Actualites',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle_rounded),
              label: 'Profil / Acces',
            ),
          ],
        ),
      ),
    );
  }
}