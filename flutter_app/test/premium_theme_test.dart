import 'package:citoyen_peyi_flutter/pages/admin_login_page.dart';
import 'package:citoyen_peyi_flutter/pages/controller_login_page.dart';
import 'package:citoyen_peyi_flutter/pages/super_admin_login_page.dart';
import 'package:citoyen_peyi_flutter/theme/app_theme.dart';
import 'package:citoyen_peyi_flutter/theme/citizen_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le thème global utilise la palette premium unique', () {
    final theme = AppTheme.light();

    expect(theme.colorScheme.primary, CitizenDesignTokens.primaryBlue);
    expect(theme.colorScheme.secondary, CitizenDesignTokens.yellowStrong);
    expect(theme.scaffoldBackgroundColor, CitizenDesignTokens.background);
    expect(theme.cardTheme.color, CitizenDesignTokens.surface);
    expect(theme.snackBarTheme.backgroundColor, CitizenDesignTokens.navy);
    expect(
      theme.navigationBarTheme.indicatorColor,
      CitizenDesignTokens.skyBlue,
    );
  });

  final loginPages = <String, Widget>{
    'administrateur': const AdminLoginPage(),
    'agent': const ControllerLoginPage(),
    'super administrateur': const SuperAdminLoginPage(),
  };

  for (final entry in loginPages.entries) {
    for (final size in const <Size>[
      Size(320, 568),
      Size(390, 844),
      Size(768, 1024),
    ]) {
      testWidgets(
        '${entry.key} reste responsive en ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: entry.value,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(TextField), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}