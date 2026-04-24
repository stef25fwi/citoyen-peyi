import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  bool _initialized = false;

  bool get isConfigured => AppConfig.isFirebaseConfigured;

  Future<void> initialize() async {
    if (_initialized || !isConfigured) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    }

    _initialized = true;
  }

  Future<void> signInWithCustomToken(String customToken) async {
    if (!isConfigured || customToken.trim().isEmpty) {
      return;
    }

    await initialize();
    await FirebaseAuth.instance.signInWithCustomToken(customToken);
  }

  Future<void> signOut() async {
    if (!isConfigured || Firebase.apps.isEmpty) {
      return;
    }

    await FirebaseAuth.instance.signOut();
  }
}
