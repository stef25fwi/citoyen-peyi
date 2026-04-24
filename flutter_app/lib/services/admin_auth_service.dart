import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_session_store.dart';
import 'firebase_auth_service.dart';

class AdminAuthException implements Exception {
  const AdminAuthException(this.message);

  final String message;
}

class AdminSignInResult {
  const AdminSignInResult({required this.isFallback});

  final bool isFallback;
}

class AdminAuthService {
  AdminAuthService._();

  static final AdminAuthService instance = AdminAuthService._();

  Future<AdminSignInResult> signInWithAccessKey(String accessKey) async {
    final trimmed = accessKey.trim();
    if (trimmed.isEmpty) {
      throw const AdminAuthException('Cle administrateur requise.');
    }

    final isLocalMode = AppConfig.apiBaseUrl.isEmpty ||
        AppConfig.apiBaseUrl.contains('localhost') ||
        AppConfig.apiBaseUrl.contains('127.0.0.1');

    if (isLocalMode) {
      final session = AuthSession(
        role: 'admin',
        admin: true,
        controller: false,
        mode: 'fallback',
        adminScope: 'global',
        label: 'Administrateur',
      );
      await AuthSessionStore.instance.save(session);
      return const AdminSignInResult(isFallback: true);
    }

    late http.Response response;
    try {
      response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/admin/exchange'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'accessKey': trimmed}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Réseau inaccessible → mode fallback
      final session = AuthSession(
        role: 'admin',
        admin: true,
        controller: false,
        mode: 'fallback',
        adminScope: 'global',
        label: 'Administrateur',
      );
      await AuthSessionStore.instance.save(session);
      return const AdminSignInResult(isFallback: true);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminAuthException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final claims = payload['claims'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final customToken = payload['customToken'] as String?;

    if (customToken != null && customToken.isNotEmpty) {
      await FirebaseAuthService.instance.signInWithCustomToken(customToken);
    }

    final session = AuthSession(
      role: claims['role'] as String? ?? 'admin',
      admin: claims['admin'] as bool? ?? true,
      controller: false,
      mode: 'secure',
      adminScope: claims['adminScope'] as String?,
      customToken: customToken,
      label: 'Administrateur',
    );

    await AuthSessionStore.instance.save(session);
    return const AdminSignInResult(isFallback: false);
  }

  String _readErrorMessage(String responseBody) {
    try {
      final payload = jsonDecode(responseBody) as Map<String, dynamic>;
      return payload['message'] as String? ?? 'Connexion administrateur impossible.';
    } catch (_) {
      return 'Connexion administrateur impossible.';
    }
  }
}
