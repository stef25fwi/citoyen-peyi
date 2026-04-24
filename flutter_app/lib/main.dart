import 'package:flutter/material.dart';

import 'app.dart';
import 'services/auth_session_store.dart';
import 'services/controleur_profile_service.dart';
import 'services/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseAuthService.instance.initialize();
  await AuthSessionStore.instance.initialize();
  await ControleurProfileService.instance.seedCode(
    code: 'ADMIN2026',
    label: 'Accès administrateur 2026',
    communeName: 'Martinique',
  );
  runApp(const CitoyenPeyiApp());
}
