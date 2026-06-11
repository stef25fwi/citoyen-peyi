import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/auth_session_store.dart';
import 'services/firebase_auth_service.dart';
import 'services/super_admin_service.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint(
            '[CitoyenPeyi] FlutterError: ${details.exceptionAsString()}');
      }
    };

    try {
      await FirebaseAuthService.instance.initialize();
    } catch (error, stackTrace) {
      debugPrint('[CitoyenPeyi] Firebase init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await AuthSessionStore.instance.initialize();
    } catch (error, stackTrace) {
      debugPrint('[CitoyenPeyi] Session store init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    // Restaure la cle super admin persistee si la session restauree est
    // super_admin (rester connecte apres fermeture, jusqu'a deconnexion).
    if (AuthSessionStore.instance.currentSession?.isSuperAdmin == true) {
      try {
        await SuperAdminService.instance.restoreRuntimeSuperAdminKey();
      } catch (error, stackTrace) {
        debugPrint('[CitoyenPeyi] Super admin key restore failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    runApp(const CitoyenPeyiApp());
  }, (error, stackTrace) {
    debugPrint('[CitoyenPeyi] Unhandled async error: $error');
    debugPrintStack(stackTrace: stackTrace);
  });
}
