import 'package:citoyen_peyi_flutter/pages/citizen/citizen_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('À propos ouvre la vraie page d’informations légales',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
    await tester.pumpAndSettle();

    final about = find.text('À propos de Citoyen Peyi');
    await tester.ensureVisible(about);
    await tester.tap(about);
    await tester.pumpAndSettle();

    expect(find.text('Informations légales'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la cloche ouvre la liste réelle des consultations',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nouvelles consultations'));
    await tester.pumpAndSettle();

    expect(find.text('Donner mon avis'), findsWidgets);
    expect(find.text('Aucune consultation en cours'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le bouton profil ouvre le profil citoyen', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mon profil'));
    await tester.pumpAndSettle();

    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Votre espace citoyen'), findsOneWidget);
    expect(find.text('Recevoir des notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const <Size>[
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
  ]) {
    testWidgets(
        'accueil connecté sans overflow en ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Bonjour !'), findsOneWidget);
      expect(find.text('Je participe'), findsOneWidget);
      expect(find.text('Comment ça marche ?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
