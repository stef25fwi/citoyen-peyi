import 'package:citoyen_peyi_flutter/widgets/public_page_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('public page components use the shared typography and spacing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                PublicPageIntro(
                  icon: Icons.article_rounded,
                  title: 'Titre public',
                  description: 'Description publique',
                ),
                SizedBox(height: 14),
                PublicEmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'État vide',
                  message: 'Message vide',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final introTitle = tester.widget<Text>(find.text('Titre public'));
    final introDescription =
        tester.widget<Text>(find.text('Description publique'));
    final emptyTitle = tester.widget<Text>(find.text('État vide'));
    final emptyMessage = tester.widget<Text>(find.text('Message vide'));

    expect(introTitle.style?.fontSize, 20);
    expect(introDescription.style?.fontSize, 14);
    expect(emptyTitle.style?.fontSize, 18);
    expect(emptyMessage.style?.fontSize, 14);
  });
}
