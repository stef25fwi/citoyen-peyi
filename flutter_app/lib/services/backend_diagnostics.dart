import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Utilitaires pour produire des messages d'erreur clairs lorsque les services
/// d'authentification n'arrivent pas a joindre le backend Cloud Run.
class BackendDiagnostics {
  const BackendDiagnostics._();

  /// Verifie que `API_BASE_URL` est utilisable depuis l'origine courante.
  /// Renvoie un message si la configuration est incoherente (URL manquante,
  /// scheme invalide, mixed-content HTTPS -> HTTP), sinon `null`.
  ///
  /// `apiBaseUrl` est injectable pour les tests ; en runtime on lit
  /// `AppConfig.apiBaseUrl` qui est defini au build via `--dart-define`.
  static String? describeConfigIssue({Uri? pageOrigin, String? apiBaseUrl}) {
    final raw = (apiBaseUrl ?? AppConfig.apiBaseUrl).trim();
    if (raw.isEmpty) {
      return 'Backend non configure (variable API_BASE_URL manquante au build).';
    }

    final apiUri = Uri.tryParse(raw);
    if (apiUri == null || !apiUri.hasScheme || apiUri.host.isEmpty) {
      return 'Backend mal configure (API_BASE_URL invalide : "$raw").';
    }

    final origin = pageOrigin ?? Uri.base;
    if (origin.scheme == 'https' && apiUri.scheme == 'http') {
      final host = apiUri.host;
      final isLoopback =
          host == 'localhost' || host == '127.0.0.1' || host == '::1';
      if (!isLoopback) {
        return 'Backend en HTTP alors que la page est servie en HTTPS ($raw). '
            'Le navigateur bloque les requetes mixtes : exposez le backend en HTTPS.';
      }
      // Page HTTPS + backend localhost : backend inaccessible depuis le navigateur.
      return 'Backend configure sur $raw mais la page est servie en HTTPS. '
          'Definissez la variable API_BASE_URL avec l\'URL publique de votre backend '
          '(ex : https://mon-backend.run.app) dans les variables du depot GitHub '
          '(Settings > Variables > Repository variables).';
    }

    return null;
  }

  /// Traduit une exception reseau brute en message actionnable. `attemptedUrl`
  /// est ajoute en queue de message pour aider au debug en developpement.
  static String describeNetworkError(Object error, {String? attemptedUrl}) {
    String suffix() => attemptedUrl == null ? '' : ' (URL : $attemptedUrl)';

    if (error is TimeoutException) {
      return 'Le backend ne repond pas (timeout 10s). Verifiez que le service est demarre.${suffix()}';
    }
    if (error is http.ClientException) {
      return 'Backend injoignable : connexion refusee, DNS introuvable ou CORS refuse. '
          'Verifiez que le service est demarre et que CORS_ORIGIN autorise ce domaine.${suffix()}';
    }
    return 'Backend injoignable (${error.runtimeType}: $error). Reessayez plus tard.${suffix()}';
  }
}
