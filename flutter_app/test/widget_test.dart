import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citoyen_peyi_flutter/app.dart';

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
    await tester.ensureVisible(termsAcceptance);
    await tester.pumpAndSettle();
    await tester.tap(termsAcceptance);
    await tester.pump();
    expect(
      find.text(
        'Veuillez d’abord consulter les informations légales avant de continuer.',
      ),
      findsOneWidget,
    );

    final legalPill = find.byKey(const ValueKey('accessCitizenLegalPill'));
    await tester.ensureVisible(legalPill);
    await tester.pumpAndSettle();
    await tester.tap(legalPill);
    await tester.pumpAndSettle();
    expect(
      find.text('CGU, confidentialité, anonymat et données personnelles'),
      findsOneWidget,
    );

    final acknowledgementButton = find.byKey(
      const ValueKey('legalAcknowledgementButton'),
    );
    await tester.ensureVisible(acknowledgementButton);
    await tester.pumpAndSettle();
    tester.widget<FilledButton>(acknowledgementButton).onPressed?.call();
    await tester.pumpAndSettle();

    await tester.ensureVisible(termsAcceptance);
    await tester.pumpAndSettle();
    await tester.tap(termsAcceptance);
    await tester.pump();

    final enabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Valider mon code citoyen'),
    );
    expect(enabledButton.onPressed, isNotNull);
  });
}
