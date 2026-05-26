import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_session_store.dart';
import 'firebase_auth_service.dart';

class ControllerAuthException implements Exception {
  const ControllerAuthException(this.message);

  final String message;
}

class ControllerSignInResult {
  const ControllerSignInResult({required this.session});

  final AuthSession session;
}

class ControllerAuthService {
  ControllerAuthService._();

  static final ControllerAuthService instance = ControllerAuthService._();

  Future<ControllerSignInResult> signInWithCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw const ControllerAuthException('Le code contrôleur est requis.');
    }

    if (AppConfig.apiBaseUrl.trim().isEmpty) {
      throw const ControllerAuthException('Backend non configuré (API_BASE_URL manquant).');
    }

    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/auth/controller/exchange'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'code': normalizedCode}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const ControllerAuthException('Backend injoignable. Réessayez plus tard.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ControllerAuthException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final profile = payload['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final claims = payload['claims'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final customToken = payload['customToken'] as String?;

    if (customToken == null || customToken.isEmpty) {
      throw const ControllerAuthException('Réponse backend invalide (customToken manquant).');
    }

    await FirebaseAuthService.instance.signInWithCustomToken(customToken);

    final session = AuthSession(
      role: claims['role'] as String? ?? 'controller',
      admin: false,
      controller: claims['controller'] as bool? ?? true,
      mode: 'secure',
      id: profile['id'] as String?,
      label: profile['label'] as String? ?? 'Contrôleur',
      commune: AuthSessionCommune.fromJson(profile['commune']),
    );

    await AuthSessionStore.instance.save(session);
    return ControllerSignInResult(session: session);
  }

  String _readErrorMessage(String responseBody) {
    try {
      final payload = jsonDecode(responseBody) as Map<String, dynamic>;
      return payload['message'] as String? ?? 'Connexion contrôleur impossible.';
    } catch (_) {
      return 'Connexion contrôleur impossible.';
    }
  }
}
