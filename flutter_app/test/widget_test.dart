import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citoyen_peyi_flutter/app.dart';
import 'package:citoyen_peyi_flutter/pages/admin_dashboard_page.dart';
import 'package:citoyen_peyi_flutter/services/auth_session_store.dart';

void main() {
  testWidgets('home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CitoyenPeyiApp());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Votre collectivité place votre parole au cœur de l\'action publique',
      ),
      findsOneWidget,
    );
    expect(find.text('Je participe'), findsOneWidget);
    expect(find.text('Accès administration'), findsOneWidget);
  });

  testWidgets('home mobile renders without a scroll view',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CitoyenPeyiApp());
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(
      find.text(
        'Votre collectivité place votre parole\nau cœur de l\'action publique',
      ),
      findsOneWidget,
    );
    expect(find.text('Je participe'), findsOneWidget);
    expect(find.text('Accès administration'), findsOneWidget);
  });

  testWidgets('citizen access requires legal terms before code validation',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const CitoyenPeyiApp());
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
    expect(find.text('Contacter le support'), findsOneWidget);
    expect(find.text('Aucune session chargée.'), findsNothing);
  });
}
