import 'package:flutter/material.dart';

import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/app_responsive_viewport.dart';

class CitoyenPeyiApp extends StatelessWidget {
  const CitoyenPeyiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citoyen Peyi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) => AppResponsiveViewport(
        child: child ?? const SizedBox.shrink(),
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: '/',
    );
  }
}
