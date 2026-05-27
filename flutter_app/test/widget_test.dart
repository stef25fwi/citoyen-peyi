import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
