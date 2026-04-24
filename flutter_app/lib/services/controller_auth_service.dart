import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_session_store.dart';
import 'browser_storage_service.dart';
import 'firebase_auth_service.dart';

class ControllerAuthException implements Exception {
  const ControllerAuthException(this.message);

  final String message;
}

class ControllerSignInResult {
  const ControllerSignInResult({
    required this.session,
    required this.isFallback,
  });

  final AuthSession session;
  final bool isFallback;
}

class ControllerAuthService {
  ControllerAuthService._();

  static const _codesStorageKey = 'controleur_codes_v1';
  static final ControllerAuthService instance = ControllerAuthService._();

  Future<ControllerSignInResult> signInWithCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw const ControllerAuthException('Le code controleur est requis.');
    }

    final isLocalMode = AppConfig.apiBaseUrl.isEmpty ||
        AppConfig.apiBaseUrl.contains('localhost') ||
        AppConfig.apiBaseUrl.contains('127.0.0.1');

    if (isLocalMode) {
      final fallbackSession = await _loadFallbackSession(normalizedCode);
      if (fallbackSession == null) {
        throw const ControllerAuthException('Code invalide. Demandez un code a un administrateur.');
      }
      await AuthSessionStore.instance.save(fallbackSession);
      return ControllerSignInResult(session: fallbackSession, isFallback: true);
    }

    late http.Response response;
    try {
      response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/controller/exchange'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'code': normalizedCode}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Réseau inaccessible → mode fallback
      final fallbackSession = await _loadFallbackSession(normalizedCode);
      if (fallbackSession == null) {
        throw const ControllerAuthException('Code invalide. Demandez un code a un administrateur.');
      }
      await AuthSessionStore.instance.save(fallbackSession);
      return ControllerSignInResult(session: fallbackSession, isFallback: true);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ControllerAuthException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final profile = payload['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final claims = payload['claims'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final customToken = payload['customToken'] as String?;

    if (customToken != null && customToken.isNotEmpty) {
      await FirebaseAuthService.instance.signInWithCustomToken(customToken);
    }

    final session = AuthSession(
      role: claims['role'] as String? ?? 'controller',
      admin: false,
      controller: claims['controller'] as bool? ?? true,
      mode: 'secure',
      customToken: customToken,
      id: profile['id'] as String?,
      code: profile['code'] as String? ?? normalizedCode,
      label: profile['label'] as String? ?? 'Controleur',
      commune: AuthSessionCommune.fromJson(profile['commune']),
    );

    await AuthSessionStore.instance.save(session);
    return ControllerSignInResult(session: session, isFallback: false);
  }

  Future<AuthSession?> _loadFallbackSession(String normalizedCode) async {
    final codes = await BrowserStorageService.instance.readJsonList(_codesStorageKey);
    final now = DateTime.now().toIso8601String();
    AuthSession? session;

    final nextCodes = codes.map((item) {
      final itemCode = (item['code'] as String? ?? '').trim().toUpperCase();
      if (itemCode != normalizedCode) {
        return item;
      }

      session = AuthSession(
        role: 'controller',
        admin: false,
        controller: true,
        mode: 'fallback',
        id: item['id'] as String?,
        code: item['code'] as String? ?? normalizedCode,
        label: item['label'] as String? ?? 'Controleur',
        commune: AuthSessionCommune.fromJson(item['commune']),
      );

      return {
        ...item,
        'usedAt': item['usedAt'] ?? now,
      };
    }).toList();

    if (session == null) {
      return null;
    }

    await BrowserStorageService.instance.writeJsonList(_codesStorageKey, nextCodes);
    return session;
  }

  String _readErrorMessage(String responseBody) {
    try {
      final payload = jsonDecode(responseBody) as Map<String, dynamic>;
      return payload['message'] as String? ?? 'Connexion controleur impossible.';
    } catch (_) {
      return 'Connexion controleur impossible.';
    }
  }
}
