import 'package:citoyen_peyi_flutter/widgets/app_responsive_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _WidthProbe extends StatelessWidget {
  const _WidthProbe();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width.round();
    return Scaffold(body: Center(child: Text('width:$width')));
  }
}

void main() {
  final cases = <({Size size, int expectedWidth})>[
    (size: const Size(320, 568), expectedWidth: 320),
    (size: const Size(360, 640), expectedWidth: 360),
    (size: const Size(390, 844), expectedWidth: 390),
    (size: const Size(768, 1024), expectedWidth: 736),
    (size: const Size(1024, 768), expectedWidth: 976),
    (size: const Size(1440, 900), expectedWidth: 1200),
  ];

  for (final testCase in cases) {
    testWidgets(
      'cadre global responsive en ${testCase.size.width}x${testCase.size.height}',
      (tester) async {
        tester.view.physicalSize = testCase.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: AppResponsiveViewport(child: _WidthProbe()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('width:${testCase.expectedWidth}'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('ResponsiveContent adapte ses marges sans overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContent(
            child: SizedBox(height: 100, child: Text('contenu')),
          ),
        ),
      ),
    );

    expect(find.text('contenu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
