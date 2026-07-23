import 'package:citoyen_peyi_flutter/pages/citizen/citizen_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la page reprend toutes les sections de la référence',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue !'), findsOneWidget);
    expect(find.text('Votre voix compte, participez\nà l’action publique'),
        findsOneWidget);
    expect(find.text('À VOUS LA PAROLE'), findsOneWidget);
    expect(find.text('Participez aux\nconsultations citoyennes'),
        findsOneWidget);
    expect(find.text('Je participe'), findsOneWidget);
    expect(find.text('En ce moment'), findsOneWidget);
    expect(find.text('Voir toutes'), findsOneWidget);
    expect(find.text('Consultation en cours'), findsOneWidget);
    expect(find.text('Comment ça marche ?'), findsOneWidget);
    expect(find.text('1. Je participe'), findsOneWidget);
    expect(find.text('2. C’est anonyme'), findsOneWidget);
    expect(find.text('3. Je vois les résultats'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la cloche ouvre le centre de notifications citoyennes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications citoyennes'));
    await tester.pumpAndSettle();

    expect(find.text('Mes notifications'), findsOneWidget);
    expect(find.text('Tout marquer comme lu'), findsOneWidget);
    expect(find.text('Aucune notification pour le moment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le logo conserve l’accès discret au profil citoyen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Mon profil'));
    await tester.pumpAndSettle();

    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Votre espace citoyen'), findsOneWidget);
    expect(find.text('Recevoir des notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
  ]) {
    testWidgets(
        'accueil connecté de référence sans overflow en ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue !'), findsOneWidget);
      expect(find.text('Je participe'), findsOneWidget);
      expect(find.text('Comment ça marche ?'), findsOneWidget);
      expect(find.byKey(const ValueKey('citizenHomeScroll')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('la navigation basse utilise le soulignement actif de la référence',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Actualités'), findsOneWidget);
    expect(find.text('Donner mon avis'), findsOneWidget);
    expect(find.text('Résultats'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
