import 'package:flutter/material.dart';

import '../pages/admin_analytics_page.dart';
import '../pages/admin_create_poll_page.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/admin_login_page.dart';
import '../pages/controller_login_page.dart';
import '../pages/home_page.dart';
import '../pages/poll_detail_page.dart';
import '../pages/placeholder_page.dart';
import '../pages/public_info_page.dart';
import '../pages/qr_access_page.dart';
import '../pages/registration_review_page.dart';
import '../pages/super_admin_dashboard_page.dart';
import '../pages/super_admin_login_page.dart';
import '../pages/vote_page.dart';
import '../services/auth_session_store.dart';
import '../widgets/public_bottom_nav.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    switch (uri.path) {
      case '/':
        return _page(const HomePage(), settings);
      case '/admin/login':
        return _page(const AdminLoginPage(), settings);
      case '/super/login':
        return _page(const SuperAdminLoginPage(), settings);
      case '/super':
        return _requireRoles(settings, const SuperAdminDashboardPage(), const ['super_admin']);
      case '/admin':
        return _requireRoles(settings, const AdminDashboardPage(), const ['admin']);
      case '/admin/analytics':
        return _requireRoles(settings, const AdminAnalyticsPage(), const ['admin']);
      case '/controleur/login':
        return _page(const ControllerLoginPage(), settings);
      case '/admin/inscriptions':
        return _requireRoles(settings, const RegistrationReviewPage(), const ['admin', 'controller']);
      case '/admin/create':
        return _requireRoles(settings, const AdminCreatePollPage(), const ['admin']);
      case '/access':
        return _page(const QrAccessPage(), settings);
      case '/results':
        return _page(
          const PublicInfoPage(
            title: 'Resultats',
            description: 'Resultats anonymes, graphiques et transparence sur les consultations ouvertes et cloturees.',
            icon: Icons.bar_chart_rounded,
            currentTab: PublicTab.results,
            primaryActionLabel: 'Acceder a mon vote',
            primaryRoute: '/access',
          ),
          settings,
        );
      case '/news':
        return _page(
          const PublicInfoPage(
            title: 'Actualites / Projets',
            description: 'Informations de la commune, projets soumis a consultation et points de contexte avant participation.',
            icon: Icons.newspaper_rounded,
            currentTab: PublicTab.news,
          ),
          settings,
        );
      case '/profile':
        return _page(
          const PublicInfoPage(
            title: 'Profil / Acces',
            description: 'Code citoyen, statut de participation, parametres, aide et CGU centralises dans un espace d\'acces unique.',
            icon: Icons.account_circle_rounded,
            currentTab: PublicTab.profile,
            primaryActionLabel: 'Entrer mon code citoyen',
            primaryRoute: '/access',
          ),
          settings,
        );
      default:
        if (uri.pathSegments.length == 3 &&
            uri.pathSegments[0] == 'admin' &&
            uri.pathSegments[1] == 'poll') {
          return _requireRoles(
            settings,
            PollDetailPage(pollId: uri.pathSegments[2]),
            const ['admin'],
          );
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

    if (allowedRoles.contains('super_admin')) {
      return _page(const SuperAdminLoginPage(), settings);
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
