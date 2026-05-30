import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class AppConfig {
  static const bool appCheckEnabled = bool.fromEnvironment(
    'APP_CHECK_ENABLED',
    defaultValue: false,
  );

  static const bool _isProductBuild = bool.fromEnvironment('dart.vm.product');

  // Valeur brute compilée. Peut être vide si --dart-define=API_BASE_URL= est
  // passé sans valeur (ex: variable GitHub non définie). Utiliser apiBaseUrl.
  static const String _apiBaseUrlRaw = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// URL du backend. En dev, retombe sur localhost. En release, une valeur
  /// vide reste vide pour exposer clairement une configuration manquante.
  static String get apiBaseUrl {
    final raw = _apiBaseUrlRaw.trim();
    if (raw.isNotEmpty) return raw;
    return _isProductBuild ? '' : 'http://localhost:4000';
  }

  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const String firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const String pushVapidKey = String.fromEnvironment(
    'PUSH_VAPID_KEY',
    defaultValue: '',
  );

  static String get resolvedFirebaseApiKey {
    final raw = firebaseApiKey.trim();
    if (raw.isNotEmpty) return raw;
    return kIsWeb ? DefaultFirebaseOptions.web.apiKey : '';
  }

  static String get resolvedFirebaseAuthDomain {
    final raw = firebaseAuthDomain.trim();
    if (raw.isNotEmpty) return raw;
    return kIsWeb ? DefaultFirebaseOptions.web.authDomain ?? '' : '';
  }

  static String get resolvedFirebaseProjectId {
    final raw = firebaseProjectId.trim();
    if (raw.isNotEmpty) return raw;
    return kIsWeb ? DefaultFirebaseOptions.web.projectId : '';
  }

  static String get resolvedFirebaseStorageBucket {
    final raw = firebaseStorageBucket.trim();
    if (raw.isNotEmpty) return raw;
    return kIsWeb ? DefaultFirebaseOptions.web.storageBucket ?? '' : '';
  }

  static String get resolvedFirebaseMessagingSenderId {
    final raw = firebaseMessagingSenderId.trim();
    if (raw.isNotEmpty) return raw;
    return kIsWeb ? DefaultFirebaseOptions.web.messagingSenderId : '';
  }

  static String get resolvedFirebaseAppId {
    final raw = firebaseAppId.trim();
    if (raw.isNotEmpty) return raw;
    return kIsWeb ? DefaultFirebaseOptions.web.appId : '';
  }

  // reCAPTCHA v3 site key used by Firebase App Check on web. The key is
  // public by design (it is embedded in every page that calls grecaptcha)
  // and only works on the domains registered on the key in the Google
  // reCAPTCHA admin console.
  static const String recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
    defaultValue: '6Ld3bPwsAAAAAAEvMDCNit9U9UhGhnSCd6CKzYfv',
  );

  static bool get isAppCheckConfigured => recaptchaSiteKey.trim().isNotEmpty;

  static bool get shouldActivateAppCheck =>
      appCheckEnabled && isAppCheckConfigured;

  static bool get isFirebaseConfigured => [
      resolvedFirebaseApiKey,
      resolvedFirebaseAuthDomain,
      resolvedFirebaseProjectId,
      resolvedFirebaseStorageBucket,
      resolvedFirebaseMessagingSenderId,
      resolvedFirebaseAppId,
      ].every((value) => value.trim().isNotEmpty);

    static FirebaseOptions get firebaseOptions => FirebaseOptions(
      apiKey: resolvedFirebaseApiKey,
      authDomain: resolvedFirebaseAuthDomain,
      projectId: resolvedFirebaseProjectId,
      storageBucket: resolvedFirebaseStorageBucket,
      messagingSenderId: resolvedFirebaseMessagingSenderId,
      appId: resolvedFirebaseAppId,
      );
}