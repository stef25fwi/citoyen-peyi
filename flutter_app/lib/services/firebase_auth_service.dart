import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../firebase_options.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  Future<void> ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }


  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;


  bool _initialized = false;

  bool get isConfigured => AppConfig.isFirebaseConfigured;

  Future<void> initialize() async {
    if (_initialized || !isConfigured) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }

    if (AppConfig.shouldActivateAppCheck) {
      try {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(AppConfig.recaptchaSiteKey),
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      } catch (error) {
        // Si le navigateur bloque reCAPTCHA, on continue sans App Check.
        // L'enforcement cote console determinera si Firestore/Auth refusent
        // les appels non attestes.
        if (kDebugMode) {
          debugPrint('[FirebaseAuthService] AppCheck activation failed: $error');
        }
      }
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
  
  Future<String?> requireFreshIdToken() async {
    await ensureInitialized();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    return user.getIdToken(true);
  }

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
