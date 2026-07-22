import 'package:citoyen_peyi_flutter/widgets/citizen/citizen_header.dart';
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

  testWidgets('public page shell is responsive from small mobile to desktop',
      (tester) async {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(768, 1024),
      Size(1024, 768),
      Size(1440, 900),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      await tester.pumpWidget(
        const MaterialApp(
          home: PublicPageShell(
            title: 'Page publique responsive',
            navigationBar: SizedBox(height: 76),
            body: PublicResponsiveList(
              children: [
                PublicPageIntro(
                  icon: Icons.article_rounded,
                  title: 'Un titre public suffisamment long pour se replier',
                  description:
                      'Une description qui reste lisible sur mobile, tablette et ordinateur sans provoquer de débordement.',
                ),
                SizedBox(height: 14),
                PublicEmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'Aucun contenu disponible',
                  message:
                      'Ce message doit conserver les mêmes proportions sur toutes les tailles d’écran.',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'taille testée : $size');

      final headerWidth = tester.getSize(find.byType(CitizenHeader)).width;
      final introWidth = tester.getSize(find.byType(PublicPageIntro)).width;

      // Le shell public ne crée plus son propre cadre centré. Il occupe la
      // largeur que lui fournit AppResponsiveViewport, ce qui évite le double
      // encadrement sur tablette et desktop.
      expect(headerWidth, closeTo(size.width, 0.1));
      expect(introWidth, lessThanOrEqualTo(860.1));
    }
  });
}