import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'services/auth_session_store.dart';
import 'services/citizen_public_access_service.dart';
import 'services/debug_log_service.dart';
import 'services/firebase_auth_service.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // google_fonts recupere ses polices (Plus Jakarta Sans, Inter) a
    // l'execution depuis fonts.gstatic.com. Sur un reseau lent/instable ou
    // bloque, Flutter Web/CanvasKit peut laisser le texte invisible
    // indefiniment en attendant ce fichier (bug connu du renderer), alors que
    // les formes/couleurs environnantes s'affichent normalement — d'ou des
    // ecrans "bandeau colore sans aucun texte". On desactive le
    // telechargement a l'execution : le theme retombe alors sur la police
    // systeme (texte toujours visible, typographie legerement differente)
    // au lieu de rester invisible en cas d'echec reseau.
    GoogleFonts.config.allowRuntimeFetching = false;

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      DebugLogService.instance
          .log('[FlutterError]', details.exceptionAsString());
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

    try {
      await CitizenPublicAccessService.instance.initialize();
    } catch (error, stackTrace) {
      debugPrint('[CitoyenPeyi] Citizen session init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    runApp(const CitoyenPeyiApp());
  }, (error, stackTrace) {
    DebugLogService.instance
        .log('[UnhandledAsync]', '$error\n$stackTrace');
    debugPrint('[CitoyenPeyi] Unhandled async error: $error');
    debugPrintStack(stackTrace: stackTrace);
  });
}
