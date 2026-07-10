import 'dart:async';
import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../firebase_options.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  String? _manualIdToken;
  DateTime? _manualIdTokenExpiresAt;

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
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }

    // Garder la session connectee tant que l'utilisateur ne se deconnecte pas
    // explicitement, meme apres fermeture de l'onglet/app (web). Sur mobile la
    // persistance est deja locale par defaut.
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
              '[FirebaseAuthService] setPersistence(LOCAL) failed: $error');
        }
      }
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
          debugPrint(
              '[FirebaseAuthService] AppCheck activation failed: $error');
        }
      }
    }

    _initialized = true;
  }

  Future<String?> currentAppCheckToken({bool forceRefresh = false}) async {
    if (!AppConfig.shouldActivateAppCheck) {
      return null;
    }
    // App Check ne doit JAMAIS faire echouer une connexion : sur certains
    // navigateurs/domaines, reCAPTCHA (et donc l'initialisation ou la
    // recuperation du jeton) peut lever une erreur — y compris un
    // "Null check operator used on a null value" non rattrape. On englobe donc
    // aussi `initialize()` dans le try et on retombe sur `null` en cas d'echec.
    // Le backend accepte les appels sans jeton (App Check est opt-in).
    try {
      await initialize();
      return await FirebaseAppCheck.instance.getToken(forceRefresh);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuthService] AppCheck token failed: $error');
      }
      return null;
    }
  }

  Future<String> signInWithCustomToken(String customToken) async {
    if (customToken.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'empty-custom-token',
        message: 'Custom token Firebase manquant.',
      );
    }
    if (!isConfigured) {
      throw FirebaseAuthException(
        code: 'firebase-not-configured',
        message: 'Configuration Firebase web manquante.',
      );
    }

    await initialize();
    try {
      final credential =
          await FirebaseAuth.instance.signInWithCustomToken(customToken);
      final user = credential.user ?? FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken(true);
      if (kDebugMode) {
        debugPrint('[FirebaseAuthService] FirebaseAuth custom token direct '
            'success, token present: ${token?.isNotEmpty == true}');
      }
      if (token == null || token.isEmpty) {
        throw FirebaseAuthException(
          code: 'empty-id-token',
          message: 'Firebase Auth n\'a pas retourné de jeton ID.',
        );
      }
      _manualIdToken = null;
      _manualIdTokenExpiresAt = null;
      return token;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuthService] FirebaseAuth custom token direct '
            'failure: $error');
      }
      rethrow;
    }
  }

  Future<String> exchangeCustomTokenViaRest(String customToken) async {
    if (customToken.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'empty-custom-token',
        message: 'Custom token Firebase manquant.',
      );
    }

    final apiKey = AppConfig.resolvedFirebaseApiKey.trim();
    if (apiKey.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-firebase-api-key',
        message: 'Clé API Firebase web manquante.',
      );
    }

    final url = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:signInWithCustomToken',
      {'key': apiKey},
    );

    try {
      final response = await http
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'token': customToken,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FirebaseAuthException(
          code: 'identity-toolkit-rest-rejected',
          message: _readRestError(response.body),
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final idToken = payload['idToken'] as String?;
      final expiresInSeconds =
          int.tryParse(payload['expiresIn']?.toString() ?? '') ?? 3600;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'empty-rest-id-token',
          message: 'Identity Toolkit n\'a pas retourné de jeton ID.',
        );
      }

      _manualIdToken = idToken;
      _manualIdTokenExpiresAt = DateTime.now()
          .add(Duration(seconds: expiresInSeconds))
          .subtract(const Duration(minutes: 1));

      if (kDebugMode) {
        debugPrint('[FirebaseAuthService] REST fallback success, token '
            'present: ${_manualIdToken?.isNotEmpty == true}');
      }
      return idToken;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuthService] REST fallback failure: $error');
      }
      rethrow;
    }
  }

  /// Returns a fresh Firebase ID token suitable for the Authorization header.
  /// Forces refresh when the cached token is older than the threshold so
  /// long-lived sessions do not silently drift past the 1h expiry.

  Future<String> requireFreshIdToken() async {
    await ensureInitialized();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken(true);
        if (kDebugMode) {
          debugPrint('[FirebaseAuthService] FirebaseAuth fresh token '
              'present: ${token?.isNotEmpty == true}');
        }
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } else if (kDebugMode) {
        debugPrint('[FirebaseAuthService] FirebaseAuth currentUser null');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuthService] FirebaseAuth fresh token failure: '
            '$error');
      }
    }

    final manualToken = _validManualIdToken;
    if (manualToken != null) {
      if (kDebugMode) {
        debugPrint('[FirebaseAuthService] Manual REST token present: true');
      }
      return manualToken;
    }

    if (kDebugMode) {
      debugPrint('[FirebaseAuthService] Manual REST token present: false');
    }
    throw FirebaseAuthException(
      code: 'super-admin-session-expired',
      message:
          'Session super administrateur expirée ou non autorisée. Reconnectez-vous.',
    );
  }

  String? get _validManualIdToken {
    final token = _manualIdToken;
    final expiresAt = _manualIdTokenExpiresAt;
    if (token == null || token.isEmpty || expiresAt == null) return null;
    if (!DateTime.now().isBefore(expiresAt)) {
      _manualIdToken = null;
      _manualIdTokenExpiresAt = null;
      return null;
    }
    return token;
  }

  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    // Cette methode ne doit JAMAIS jeter : tout incident (plugin web qui
    // deballe un null, init en cours, etc.) retombe sur le token REST
    // manuel ou renvoie null. L'appelant decide alors quoi faire.
    try {
      if (!isConfigured) return _validManualIdToken;
      try {
        await initialize();
      } catch (_) {
        return _validManualIdToken;
      }
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {
        return _validManualIdToken;
      }
      if (user == null) {
        return _validManualIdToken;
      }
      try {
        final token = await user.getIdToken(forceRefresh);
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } catch (_) {
        if (forceRefresh) {
          try {
            final token = await user.getIdToken();
            if (token != null && token.isNotEmpty) {
              return token;
            }
          } catch (_) {}
        }
      }
      return _validManualIdToken;
    } catch (_) {
      return _validManualIdToken;
    }
  }

  Stream<User?> get authStateChanges {
    if (!isConfigured) return const Stream<User?>.empty();
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<void> signOut() async {
    _manualIdToken = null;
    _manualIdTokenExpiresAt = null;
    if (!isConfigured || Firebase.apps.isEmpty) {
      return;
    }

    await FirebaseAuth.instance.signOut();
  }

  String _readRestError(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      final error = payload['error'];
      if (error is Map<String, dynamic>) {
        return error['message'] as String? ??
            'Authentification Firebase refusée.';
      }
      return payload['message'] as String? ??
          'Authentification Firebase refusée.';
    } catch (_) {
      return 'Authentification Firebase refusée.';
    }
  }
}
