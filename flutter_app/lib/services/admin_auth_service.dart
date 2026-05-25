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
  const AdminSignInResult({required this.session});

  final AuthSession session;
}

class AdminAuthService {
  AdminAuthService._();

  static final AdminAuthService instance = AdminAuthService._();

  Future<AdminSignInResult> signInWithAccessKey(String accessKey) async {
    final trimmed = accessKey.trim();
    if (trimmed.isEmpty) {
      throw const AdminAuthException('Cle administrateur requise.');
    }

    if (AppConfig.apiBaseUrl.trim().isEmpty) {
      throw const AdminAuthException('Backend non configure (API_BASE_URL manquant).');
    }

    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/auth/admin/exchange'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'accessKey': trimmed}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const AdminAuthException('Backend injoignable. Reessayez plus tard.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminAuthException(_readErrorMessage(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final claims = payload['claims'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final profile = payload['profile'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final customToken = payload['customToken'] as String?;

    if (customToken == null || customToken.isEmpty) {
      throw const AdminAuthException('Reponse backend invalide (customToken manquant).');
    }

    await FirebaseAuthService.instance.signInWithCustomToken(customToken);

    final session = AuthSession(
      role: claims['role'] as String? ?? 'commune_admin',
      admin: claims['admin'] as bool? ?? true,
      controller: false,
      mode: 'secure',
      adminScope: claims['adminScope'] as String?,
      customToken: customToken,
      id: profile['id'] as String?,
      label: profile['label'] as String? ?? 'Administrateur communal',
      commune: profile['communeName'] is String && (profile['communeName'] as String).isNotEmpty
          ? AuthSessionCommune(
              name: profile['communeName'] as String,
              code: profile['communeId'] as String?,
            )
          : null,
    );

    await AuthSessionStore.instance.save(session);
    return AdminSignInResult(session: session);
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
