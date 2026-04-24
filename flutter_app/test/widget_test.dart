import 'package:flutter_test/flutter_test.dart';

import 'package:citoyen_peyi_flutter/app.dart';

void main() {
  testWidgets('home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CitoyenPeyiApp());
    await tester.pumpAndSettle();

    expect(find.text('Plateforme de sondage anonyme'), findsOneWidget);
    expect(find.text('Espace Admin'), findsOneWidget);
  });
}
