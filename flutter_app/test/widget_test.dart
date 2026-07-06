import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citoyen_peyi_flutter/app.dart';
import 'package:citoyen_peyi_flutter/models/support_message.dart';
import 'package:citoyen_peyi_flutter/models/support_ticket.dart';
import 'package:citoyen_peyi_flutter/pages/admin_dashboard_page.dart';
import 'package:citoyen_peyi_flutter/routes/app_router.dart';
import 'package:citoyen_peyi_flutter/screens/admin/support/admin_create_ticket_screen.dart';
import 'package:citoyen_peyi_flutter/screens/admin/support/admin_support_list_screen.dart';
import 'package:citoyen_peyi_flutter/screens/super_admin/support/super_admin_support_list_screen.dart';
import 'package:citoyen_peyi_flutter/services/auth_session_store.dart';
import 'package:citoyen_peyi_flutter/widgets/support/ticket_card.dart';
import 'package:citoyen_peyi_flutter/widgets/support/ticket_message_bubble.dart';

void main() {
  testWidgets('home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CitoyenPeyiApp());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Votre collectivité place\nvotre parole\nau cœur de l\'action publique',
      ),
      findsOneWidget,
    );
    expect(find.text('Je participe'), findsOneWidget);
    expect(find.text('Accès administration'), findsOneWidget);
  });

  testWidgets('home mobile shows admin access within the viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CitoyenPeyiApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(
      find.text(
        'Votre collectivité place\nvotre parole\nau cœur de l\'action publique',
      ),
      findsOneWidget,
    );
    expect(find.text('Je participe'), findsOneWidget);
    expect(find.text('Accès administration'), findsOneWidget);

    // L'acces administration doit rester visible dans le viewport mobile sans
    // avoir besoin de faire defiler la page.
    final adminRect = tester.getRect(find.text('Accès administration'));
    expect(adminRect.bottom, lessThanOrEqualTo(844));
  });

  testWidgets('citizen access requires legal terms before code validation',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const CitoyenPeyiApp());
    await tester.pumpAndSettle();

    // Sur la largeur de test par defaut (800x600, palier tablette), la page
    // d'accueil est dans un SingleChildScrollView : le bouton peut etre hors
    // du viewport initial. On le rend visible avant de taper dessus, comme le
    // ferait un utilisateur reel en faisant defiler la page.
    await tester.ensureVisible(find.text('Je participe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je participe'));
    await tester.pumpAndSettle();

    expect(find.text('Accès citoyen'), findsWidgets);
    expect(
      find.text('CGU, confidentialité et données personnelles'),
      findsOneWidget,
    );
    expect(
      find.text('Faites défiler le texte jusqu’à la fin pour accepter'),
      findsOneWidget,
    );
    expect(
      find.text('Entrez votre code citoyen pour participer anonymement.'),
      findsOneWidget,
    );

    final disabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Valider mon code citoyen'),
    );
    expect(disabledButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'CP-2026-ABCD');
    await tester.pump();

    final stillDisabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Valider mon code citoyen'),
    );
    expect(stillDisabledButton.onPressed, isNull);

    final termsAcceptance = find.byKey(
      const ValueKey('accessCitizenTermsAcceptance'),
    );
    expect(termsAcceptance, findsNothing);

    final legalScroll = find.byKey(
      const ValueKey('accessCitizenLegalTermsScroll'),
    );
    await tester.ensureVisible(legalScroll);
    await tester.pumpAndSettle();
    final legalScrollable = find.descendant(
      of: find.byKey(const ValueKey('accessCitizenLegalPill')),
      matching: find.byType(Scrollable),
    );
    final scrollableState = tester.state<ScrollableState>(legalScrollable);
    scrollableState.position.jumpTo(scrollableState.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(termsAcceptance, findsOneWidget);
    expect(find.text('Lecture complète effectuée'), findsOneWidget);

    await tester.ensureVisible(termsAcceptance);
    await tester.pumpAndSettle();
    await tester.tap(termsAcceptance);
    await tester.pump();

    final enabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Valider mon code citoyen'),
    );
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets('commune admin dashboard renders assistance without grey screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AuthSessionStore.instance.initialize();
    await AuthSessionStore.instance.save(
      const AuthSession(
        role: 'commune_admin',
        admin: true,
        controller: false,
        mode: 'secure',
        id: 'admin-test',
        label: 'Admin test',
        commune: AuthSessionCommune(name: 'Les Abymes', code: '97101'),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: AdminDashboardPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Tableau de bord commune'), findsWidgets);
    expect(find.text('Session admin communal'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.text('Assistance'), findsWidgets);
    expect(find.text('Nouveau ticket d’assistance'), findsOneWidget);
    expect(find.text('Mes tickets'), findsOneWidget);
    expect(find.text('Impossible de charger l’assistance pour le moment.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Aucune session chargée.'), findsNothing);
  });

  testWidgets('commune admin assistance page renders on mobile without grey screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await AuthSessionStore.instance.initialize();
    await AuthSessionStore.instance.save(
      const AuthSession(
        role: 'commune_admin',
        admin: true,
        controller: false,
        mode: 'secure',
        id: 'admin-test',
        label: 'Admin test',
        commune: AuthSessionCommune(name: 'Les Abymes', code: '97101'),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: AdminSupportListScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Assistance'), findsWidgets);
    expect(find.byTooltip('Nouveau ticket'), findsOneWidget);
    expect(
      find.text('Impossible de charger les tickets pour le moment. Vérifiez votre connexion puis réessayez.'),
      findsOneWidget,
    );
  });

  testWidgets('commune admin assistance button opens support page',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AuthSessionStore.instance.initialize();
    await AuthSessionStore.instance.save(
      const AuthSession(
        role: 'commune_admin',
        admin: true,
        controller: false,
        mode: 'secure',
        id: 'admin-test',
        label: 'Admin test',
        commune: AuthSessionCommune(name: 'Les Abymes', code: '97101'),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: '/admin',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final assistanceButton = find.widgetWithText(FilledButton, 'Assistance');
    await tester.scrollUntilVisible(assistanceButton, 240);
    await tester.pumpAndSettle();
    await tester.tap(assistanceButton);
    await tester.pumpAndSettle();

    expect(find.text('Assistance'), findsWidgets);
    expect(find.byTooltip('Nouveau ticket'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Nouveau ticket'), findsOneWidget);
    expect(
      find.text('Impossible de charger les tickets pour le moment. Vérifiez votre connexion puis réessayez.'),
      findsOneWidget,
    );
    expect(find.text('Aucune session chargée.'), findsNothing);
  });

  testWidgets('commune admin assistance button opens support page on mobile',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await AuthSessionStore.instance.initialize();
    await AuthSessionStore.instance.save(
      const AuthSession(
        role: 'commune_admin',
        admin: true,
        controller: false,
        mode: 'secure',
        id: 'admin-test',
        label: 'Admin test',
        commune: AuthSessionCommune(name: 'Les Abymes', code: '97101'),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: '/admin',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final assistanceButton = find.widgetWithText(FilledButton, 'Assistance');
    await tester.scrollUntilVisible(assistanceButton, 240);
    await tester.pumpAndSettle();
    await tester.tap(assistanceButton);
    await tester.pumpAndSettle();

    expect(find.text('Assistance'), findsWidgets);
    expect(find.byTooltip('Nouveau ticket'), findsOneWidget);
    expect(
      find.text('Impossible de charger les tickets pour le moment. Vérifiez votre connexion puis réessayez.'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('admin ticket form validates required fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminCreateTicketScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Envoyer au super admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer au super admin'));
    await tester.pump();

    expect(find.text('Sujet minimum 5 caractères.'), findsOneWidget);
    expect(find.text('Catégorie obligatoire.'), findsOneWidget);
    expect(find.text('Message minimum 10 caractères.'), findsOneWidget);
  });

  testWidgets('super admin assistance page has clear unavailable state',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SuperAdminSupportListScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Tickets assistance'), findsWidgets);
    expect(
      find.text('Impossible de charger les tickets d’assistance pour le moment.'),
      findsOneWidget,
    );
  });

  testWidgets('ticket card displays unread support badge',
      (WidgetTester tester) async {
    const ticket = SupportTicket(
      ticketId: 'ticket-1',
      communeId: '97101',
      communeName: 'Les Abymes',
      createdByUserId: 'admin-1',
      createdByName: 'Admin test',
      createdByEmail: 'admin@example.test',
      createdByRole: 'admin_communal',
      assignedToRole: 'super_admin',
      subject: 'Besoin aide consultation',
      category: 'Problème technique',
      priority: 'urgente',
      status: 'ouvert',
      lastMessage: 'Une réponse du super administrateur est disponible.',
      lastMessageByRole: 'super_admin',
      messagesCount: 2,
      unreadForSuperAdmin: false,
      unreadForAdmin: true,
      createdAt: '2026-01-01T10:00:00Z',
      updatedAt: '2026-01-01T11:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TicketCard(
            ticket: ticket,
            showUnreadForAdmin: true,
            onOpen: () {},
          ),
        ),
      ),
    );

    expect(find.text('Nouveau'), findsOneWidget);
    expect(find.text('Ouvrir'), findsOneWidget);
  });

  testWidgets('system support messages render as centered notes',
      (WidgetTester tester) async {
    const message = SupportMessage(
      messageId: 'message-1',
      ticketId: 'ticket-1',
      senderId: 'system',
      senderName: 'Système',
      senderEmail: '',
      senderRole: 'system',
      message: 'Le ticket est passé au statut : En cours.',
      createdAt: '2026-01-01T10:00:00Z',
      isInternal: true,
      readBySuperAdmin: true,
      readByAdmin: false,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TicketMessageBubble(
            message: message,
            currentRole: 'admin_communal',
          ),
        ),
      ),
    );

    expect(find.text('Le ticket est passé au statut : En cours.'), findsOneWidget);
  });
}
