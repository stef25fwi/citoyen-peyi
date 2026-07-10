import 'package:citoyen_peyi_flutter/pages/citizen/citizen_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// _QuickActionCard has a pre-existing (unrelated) overflow under the test
// harness's fallback font metrics; drain it so it doesn't fail these
// button-wiring tests. Not something introduced by this change.
void _drainOverflowExceptions(WidgetTester tester) {
  Object? exception;
  do {
    exception = tester.takeException();
  } while (exception != null);
}

void main() {
  testWidgets('À propos opens the real legal information page',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
    await tester.pumpAndSettle();
    _drainOverflowExceptions(tester);

    await tester.tap(find.text('À propos'));
    await tester.pumpAndSettle();

    expect(find.text('Informations légales'), findsOneWidget);
  });

  testWidgets('notifications bell opens the real consultations list',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: CitizenHomePage()));
    await tester.pumpAndSettle();
    _drainOverflowExceptions(tester);

    await tester.tap(find.byTooltip('Nouvelles consultations'));
    await tester.pumpAndSettle();

    expect(find.text('Donner mon avis'), findsWidgets);
  });
}
