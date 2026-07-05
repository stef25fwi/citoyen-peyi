import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_session_store.dart';
import 'backend_diagnostics.dart';
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
    var normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.startsWith('CTRL-')) {
      normalizedCode = normalizedCode.substring(5);
    }
    if (normalizedCode.isEmpty) {
      throw const ControllerAuthException('Le code agent de mobilisation citoyenne est requis.');
    }

    final configIssue = BackendDiagnostics.describeConfigIssue();
    if (configIssue != null) {
      throw ControllerAuthException(configIssue);
    }

    final url = '${AppConfig.apiBaseUrl}/api/auth/controller/exchange';
    final appCheckToken = await FirebaseAuthService.instance.currentAppCheckToken();
    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (appCheckToken != null && appCheckToken.isNotEmpty)
                'X-Firebase-AppCheck': appCheckToken,
            },
            body: jsonEncode({'code': normalizedCode}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      throw ControllerAuthException(
          BackendDiagnostics.describeNetworkError(error, attemptedUrl: url));
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

    await _signInWithCustomTokenWithFallback(customToken);

    final session = AuthSession(
      role: claims['role'] as String? ?? 'controller',
      admin: false,
      controller: claims['controller'] as bool? ?? true,
      mode: 'secure',
      id: profile['id'] as String?,
      label: profile['label'] as String? ?? 'Agent de mobilisation citoyenne',
      commune: AuthSessionCommune.fromJson(profile['commune']),
    );

    await AuthSessionStore.instance.save(session);
    return ControllerSignInResult(session: session);
  }

  String _readErrorMessage(String responseBody) {
    try {
      final payload = jsonDecode(responseBody) as Map<String, dynamic>;
      return payload['message'] as String? ?? 'Connexion agent de mobilisation citoyenne impossible.';
    } catch (_) {
      return 'Connexion agent de mobilisation citoyenne impossible.';
    }
  }

  Future<void> _signInWithCustomTokenWithFallback(String customToken) async {
    try {
      await FirebaseAuthService.instance.signInWithCustomToken(customToken);
      return;
    } catch (_) {
      // Repli REST pour Safari/iPad.
    }
    try {
      await FirebaseAuthService.instance
          .exchangeCustomTokenViaRest(customToken);
    } catch (error) {
      throw ControllerAuthException(
        'Authentification Firebase refusée. Reessayez ou videz le cache du navigateur (${error.toString()}).',
      );
    }
  }
}
