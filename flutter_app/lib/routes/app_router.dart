import 'package:flutter/material.dart';

import '../pages/admin_dashboard_page.dart';
import '../pages/admin_login_page.dart';
import '../pages/controller_login_page.dart';
import '../pages/home_page.dart';
import '../pages/placeholder_page.dart';
import '../pages/qr_access_page.dart';
import '../pages/registration_review_page.dart';
import '../pages/vote_page.dart';
import '../services/auth_session_store.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    switch (uri.path) {
      case '/':
        return _page(const HomePage(), settings);
      case '/admin/login':
        return _page(const AdminLoginPage(), settings);
      case '/admin':
        return _requireRoles(settings, const AdminDashboardPage(), const ['admin']);
      case '/admin/analytics':
        return _requireRoles(settings, const PlaceholderPage(title: 'Analytics admin'), const ['admin']);
      case '/controleur/login':
        return _page(const ControllerLoginPage(), settings);
      case '/admin/inscriptions':
        return _requireRoles(settings, const RegistrationReviewPage(), const ['admin', 'controller']);
      case '/admin/create':
        return _requireRoles(settings, const PlaceholderPage(title: 'Creation de sondage'), const ['admin']);
      case '/access':
        return _page(const QrAccessPage(), settings);
      default:
        if (uri.pathSegments.length == 3 &&
            uri.pathSegments[0] == 'admin' &&
            uri.pathSegments[1] == 'poll') {
          return _placeholder(settings, 'Detail du sondage', subtitle: 'Identifiant: ${uri.pathSegments[2]}');
        }

        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'vote') {
          return _page(VotePage(token: uri.pathSegments[1]), settings);
        }

        return _placeholder(settings, 'Page introuvable', subtitle: uri.path);
    }
  }

  static MaterialPageRoute<void> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute<void>(builder: (_) => child, settings: settings);
  }

  static MaterialPageRoute<void> _requireRoles(
    RouteSettings settings,
    Widget child,
    List<String> allowedRoles,
  ) {
    if (AuthSessionStore.instance.currentSession?.hasAnyRole(allowedRoles) == true) {
      return _page(child, settings);
    }

    return _page(
      allowedRoles.contains('controller')
          ? const ControllerLoginPage()
          : const AdminLoginPage(
              blockedMessage: 'Authentification administrateur requise pour acceder a cette page.',
            ),
      settings,
    );
  }

  static MaterialPageRoute<void> _placeholder(
    RouteSettings settings,
    String title, {
    String? subtitle,
  }) {
    return _page(PlaceholderPage(title: title, subtitle: subtitle), settings);
  }
}
