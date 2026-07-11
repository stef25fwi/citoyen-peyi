import 'package:flutter/material.dart';

import '../pages/admin_analytics_page.dart';
import '../pages/admin_create_poll_page.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/admin_edit_poll_page.dart';
import '../pages/admin_settings_page.dart';
import '../pages/admin_login_page.dart';
import '../pages/access_citizen_page.dart';
import '../pages/commune_controller_activity_page.dart';
import '../pages/controller_citizen_access_page.dart';
import '../pages/controller_login_page.dart';
import '../pages/controller_dashboard_page.dart';
import '../pages/controller_history_page.dart';
import '../pages/controller_activity_dashboard_page.dart';
import '../pages/citizen/citizen_consultations_page.dart';
import '../pages/citizen/citizen_home_page.dart';
import '../pages/citizen/citizen_poll_question_page.dart';
import '../pages/citizen/citizen_welcome_page.dart';
import '../pages/duplicate_request_detail_page.dart';
import '../pages/duplicate_request_list_page.dart';
import '../pages/home_page.dart';
import '../pages/legal_page.dart';
import '../pages/poll_detail_page.dart';
import '../pages/placeholder_page.dart';
import '../pages/public_news_page.dart';
import '../pages/public_results_page.dart';
import '../pages/public_vote_page.dart';
import '../pages/super_admin_agents_page.dart';
import '../pages/super_admin_communes_page.dart';
import '../pages/super_admin_dashboard_page.dart';
import '../pages/super_admin_backup_page.dart';
import '../screens/admin/support/admin_create_ticket_screen.dart';
import '../screens/admin/support/admin_support_list_screen.dart';
import '../screens/admin/support/admin_ticket_detail_screen.dart';
import '../screens/super_admin/support/super_admin_support_list_screen.dart';
import '../screens/super_admin/support/super_admin_ticket_detail_screen.dart';
import '../pages/vote_confirmation_page.dart';
import '../pages/super_admin_login_page.dart';
import '../pages/vote_page.dart';
import '../services/auth_session_store.dart';
import '../services/citizen_public_access_service.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    switch (uri.path) {
      case '/':
      case '/accueil':
        return _page(const HomePage(), settings);
      case '/admin-communal':
        return _page(const AdminLoginPage(), settings);
      case '/admin/login':
        return _page(const AdminLoginPage(), settings);
      case '/super-admin':
        return _page(const SuperAdminLoginPage(), settings);
      case '/super/login':
        return _page(const SuperAdminLoginPage(), settings);
      case '/super':
        return _requireRoles(
            settings, const SuperAdminDashboardPage(), const ['super_admin']);
      case '/super/duplicates':
        return _requireRoles(
            settings, const DuplicateRequestListPage(), const ['super_admin']);
      case '/super/activity':
        return _requireRoles(settings, const ControllerActivityDashboardPage(),
            const ['super_admin']);
      case '/super-admin/support':
      case '/super/support':
        return _requireRoles(settings, const SuperAdminSupportListScreen(),
            const ['super_admin']);
      case '/super/controllers':
        return _requireRoles(
            settings, const SuperAdminAgentsPage(), const ['super_admin']);
      case '/super/communes':
        return _requireRoles(
            settings, const SuperAdminCommunesPage(), const ['super_admin']);
      case '/super/backups':
        return _requireRoles(
            settings, const SuperAdminBackupPage(), const ['super_admin']);
      case '/super/admins':
        return _requireRoles(
          settings,
          const SuperAdminDashboardPage(
              initialSection: SuperAdminDashboardSection.admins),
          const ['super_admin'],
        );
      case '/admin':
        return _requireRoles(
            settings, const AdminDashboardPage(), const ['commune_admin']);
      case '/admin/analytics':
        return _page(
          const _LegacyRouteRedirectPage(
            targetRoute: '/admin/results',
            message:
                'La page Analytics a ete remplacee par Resultats dans le parcours administrateur communal.',
          ),
          settings,
        );
      case '/admin/controllers':
        return _requireRoles(
          settings,
          const AdminDashboardPage(
              initialSection: AdminDashboardSection.controllers),
          const ['commune_admin'],
        );
      case '/admin/polls':
        return _requireRoles(
          settings,
          const AdminDashboardPage(initialSection: AdminDashboardSection.polls),
          const ['commune_admin'],
        );
      case '/admin/polls/create':
        return _requireRoles(
            settings, const AdminCreatePollPage(), const ['commune_admin']);
      case '/admin/results':
        return _requireRoles(
            settings, const AdminAnalyticsPage(), const ['commune_admin']);
      case '/admin/support':
        return _requireRoles(
            settings, const AdminSupportListScreen(), const ['commune_admin']);
      case '/admin/support/new':
        return _requireRoles(
            settings, const AdminCreateTicketScreen(), const ['commune_admin']);
      case '/admin/settings':
        return _requireRoles(
            settings, const AdminSettingsPage(), const ['commune_admin']);
      case '/controleur/login':
        return _page(const ControllerLoginPage(), settings);
      case '/controleur-accueil':
        return _page(const ControllerLoginPage(), settings);
      case '/controleur':
        return _requireRoles(
            settings, const ControllerDashboardPage(), const ['controller']);
      case '/controleur/acces-citoyen':
        return _requireRoles(settings, const ControllerCitizenAccessPage(),
            const ['controller']);
      case '/controleur/historique':
        return _requireRoles(
            settings, const ControllerHistoryPage(), const ['controller']);
      case '/admin/inscriptions':
        return _page(
          const _LegacyRouteRedirectPage(
            targetRoute: '/controleur/acces-citoyen',
            message:
                'Le parcours Inscriptions a ete deplace vers Acces citoyen dans l\'espace agent de mobilisation citoyenne.',
          ),
          settings,
        );
      case '/admin/create':
        return _page(
          const _LegacyRouteRedirectPage(
            targetRoute: '/admin/polls/create',
            message:
                'La creation de consultation est maintenant disponible dans le parcours administrateur communal.',
          ),
          settings,
        );
      case '/access':
      case '/avis':
      case '/participer':
      case '/espace-citoyen':
      case AccessCitizenPage.routeName:
        return _page(
          AccessCitizenPage(initialCode: uri.queryParameters['code']),
          settings,
        );
      case LegalPage.routeName:
        return _page(const LegalPage(), settings);
      case '/citizen':
        return _page(
          CitizenHomePage(
              initialSession: _readCitizenAccessSession(settings.arguments)),
          settings,
        );
      case '/citizen/polls':
        return _page(
          CitizenConsultationsPage(
              initialSession: _readCitizenAccessSession(settings.arguments)),
          settings,
        );
      case '/citizen/welcome':
        return _page(
          CitizenWelcomePage(
            initialSession: _readCitizenAccessSession(settings.arguments),
          ),
          settings,
        );
      case '/citizen/home':
        return _page(
          CitizenHomePage(
              initialSession: _readCitizenAccessSession(settings.arguments)),
          settings,
        );
      case '/citizen/consultations':
        return _page(
          CitizenConsultationsPage(
              initialSession: _readCitizenAccessSession(settings.arguments)),
          settings,
        );
      case '/confirmation':
        return _page(
          VoteConfirmationPage(
            pollTitle: _readStringArgument(settings.arguments, 'pollTitle'),
            communeName: _readStringArgument(settings.arguments, 'communeName'),
          ),
          settings,
        );
      case '/results':
      case '/resultats':
        return _page(const PublicResultsPage(), settings);
      case '/news':
      case '/actualites':
        return _page(const PublicNewsPage(), settings);
      case '/donner-mon-avis':
        return _page(const PublicVotePage(), settings);
      case '/profile':
        return _page(
          const _LegacyRouteRedirectPage(
            targetRoute: '/citizen/home',
            message:
                'Le profil public a ete remplace par l\'espace citoyen accessible avec un code valide.',
          ),
          settings,
        );
      default:
        if (uri.pathSegments.length == 3 &&
            uri.pathSegments[0] == 'super' &&
            uri.pathSegments[1] == 'duplicates') {
          return _requireRoles(
            settings,
            DuplicateRequestDetailPage(requestId: uri.pathSegments[2]),
            const ['super_admin'],
          );
        }

        if (uri.pathSegments.length == 4 &&
            uri.pathSegments[0] == 'super' &&
            uri.pathSegments[1] == 'activity' &&
            uri.pathSegments[2] == 'commune') {
          return _requireRoles(
            settings,
            CommuneControllerActivityPage(communeId: uri.pathSegments[3]),
            const ['super_admin'],
          );
        }

        if (uri.pathSegments.length == 3 &&
            uri.pathSegments[0] == 'admin' &&
            uri.pathSegments[1] == 'support') {
          return _requireRoles(
            settings,
            AdminTicketDetailScreen(ticketId: uri.pathSegments[2]),
            const ['commune_admin'],
          );
        }

        if (uri.pathSegments.length == 3 &&
            uri.pathSegments[0] == 'super-admin' &&
            uri.pathSegments[1] == 'support') {
          return _requireRoles(
            settings,
            SuperAdminTicketDetailScreen(ticketId: uri.pathSegments[2]),
            const ['super_admin'],
          );
        }

        if (uri.pathSegments.length == 3 &&
            uri.pathSegments[0] == 'admin' &&
            uri.pathSegments[1] == 'poll') {
          return _requireRoles(
            settings,
            PollDetailPage(pollId: uri.pathSegments[2]),
            const ['commune_admin', 'super_admin'],
          );
        }

        if (uri.pathSegments.length == 4 &&
            uri.pathSegments[0] == 'admin' &&
            uri.pathSegments[1] == 'polls' &&
            uri.pathSegments[3] == 'edit') {
          return _requireRoles(
            settings,
            AdminEditPollPage(pollId: uri.pathSegments[2]),
            const ['commune_admin', 'super_admin'],
          );
        }

        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'vote') {
          return _page(
              VotePage(
                  token: uri.pathSegments[1],
                  pollId: uri.queryParameters['poll']),
              settings);
        }

        if (uri.pathSegments.length == 3 &&
            uri.pathSegments[0] == 'citizen' &&
            uri.pathSegments[1] == 'consultation') {
          final title = Uri.decodeComponent(uri.pathSegments[2]);
          final session = _readCitizenAccessSession(settings.arguments);
          final pollId = uri.queryParameters['poll']?.trim();
          final accessCode = uri.queryParameters['code']?.trim() ??
              uri.queryParameters['accessCode']?.trim() ??
              session?.accessCode;
          return _page(
            CitizenPollQuestionPage(
              title: title,
              pollId: pollId?.isNotEmpty == true ? pollId : null,
              accessCode: accessCode?.isNotEmpty == true ? accessCode : null,
            ),
            settings,
          );
        }

        return _placeholder(settings, 'Page introuvable', subtitle: uri.path);
    }
  }

  static Route<void> _page(Widget child, RouteSettings settings) {
    if (_shouldDisableTransition(settings)) {
      return PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (_, __, ___) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, __, ___, pageChild) => pageChild,
      );
    }

    return MaterialPageRoute<void>(builder: (_) => child, settings: settings);
  }

  static Route<void> _requireRoles(
    RouteSettings settings,
    Widget child,
    List<String> allowedRoles,
  ) {
    if (AuthSessionStore.instance.currentSession?.hasAnyRole(allowedRoles) ==
        true) {
      return _page(child, settings);
    }

    if (allowedRoles.contains('super_admin')) {
      return _page(const SuperAdminLoginPage(), settings);
    }

    return _page(
      allowedRoles.contains('controller')
          ? const ControllerLoginPage()
          : const AdminLoginPage(
              blockedMessage:
                  'Authentification administrateur communal requise pour acceder a cette page.',
            ),
      settings,
    );
  }

  static Route<void> _placeholder(
    RouteSettings settings,
    String title, {
    String? subtitle,
  }) {
    return _page(PlaceholderPage(title: title, subtitle: subtitle), settings);
  }

  static bool _shouldDisableTransition(RouteSettings settings) {
    final arguments = settings.arguments;
    if (arguments is Map<Object?, Object?>) {
      return arguments['disableTransition'] == true;
    }

    return false;
  }

  static CitizenPublicAccessSession? _readCitizenAccessSession(
      Object? arguments) {
    if (arguments is Map<Object?, Object?>) {
      final session = arguments['session'];
      if (session is CitizenPublicAccessSession) {
        return session;
      }
    }

    return CitizenPublicAccessService.instance.currentSession;
  }

  static String? _readStringArgument(Object? arguments, String key) {
    if (arguments is Map<Object?, Object?>) {
      final value = arguments[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}

class _LegacyRouteRedirectPage extends StatefulWidget {
  const _LegacyRouteRedirectPage({
    required this.targetRoute,
    required this.message,
  });

  final String targetRoute;
  final String message;

  @override
  State<_LegacyRouteRedirectPage> createState() =>
      _LegacyRouteRedirectPageState();
}

class _LegacyRouteRedirectPageState extends State<_LegacyRouteRedirectPage> {
  bool _redirectScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_redirectScheduled) {
      return;
    }

    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.message)),
      );
      Navigator.of(context).pushReplacementNamed(widget.targetRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
