import 'dart:async';

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

  /// Returns a fresh Firebase ID token suitable for the Authorization header.
  /// Forces refresh when the cached token is older than the threshold so
  /// long-lived sessions do not silently drift past the 1h expiry.
  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    if (!isConfigured) return null;
    await initialize();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    if (!isConfigured) return const Stream<User?>.empty();
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<void> signOut() async {
    if (!isConfigured || Firebase.apps.isEmpty) {
      return;
    }

    await FirebaseAuth.instance.signOut();
  }
}
