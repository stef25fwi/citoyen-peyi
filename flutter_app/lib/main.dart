import 'package:flutter/material.dart';

import 'app.dart';
import 'services/auth_session_store.dart';
import 'services/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseAuthService.instance.initialize();
  await AuthSessionStore.instance.initialize();
  runApp(const CitoyenPeyiApp());
}
