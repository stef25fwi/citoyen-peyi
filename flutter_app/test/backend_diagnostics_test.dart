import 'dart:async';

import 'package:citoyen_peyi_flutter/services/backend_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('BackendDiagnostics.describeConfigIssue', () {
    test('signale une URL vide', () {
      final issue = BackendDiagnostics.describeConfigIssue(
        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
        apiBaseUrl: '',
      );
      expect(issue, isNotNull);
      expect(issue, contains('API_BASE_URL'));
    });

    test('signale une URL invalide', () {
      final issue = BackendDiagnostics.describeConfigIssue(
        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
        apiBaseUrl: 'not-an-url',
      );
      expect(issue, isNotNull);
      expect(issue, contains('invalide'));
    });

    test(
        'signale le mixed-content quand la page est HTTPS et l\'API en HTTP non-loopback',
        () {
      final issue = BackendDiagnostics.describeConfigIssue(
        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
        apiBaseUrl: 'http://api.example.com',
      );
      expect(issue, isNotNull);
      expect(issue, contains('HTTPS'));
      expect(issue, contains('http://api.example.com'));
    });

    test('signale localhost HTTP depuis une page HTTPS de production', () {
      final issue = BackendDiagnostics.describeConfigIssue(
        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
        apiBaseUrl: 'http://localhost:4000',
      );
      expect(issue, isNotNull);
      expect(issue, contains('http://localhost:4000'));
      expect(issue, contains('API_BASE_URL'));
    });

    test('autorise une configuration valide', () {
      final issue = BackendDiagnostics.describeConfigIssue(
        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
        apiBaseUrl: 'https://api.citoyen-peyi.fr',
      );
      expect(issue, isNull);
    });
  });

  group('BackendDiagnostics.describeNetworkError', () {
    test('mentionne le timeout', () {
      final message = BackendDiagnostics.describeNetworkError(
        TimeoutException('timeout'),
      );
      expect(message, contains('timeout'));
    });

    test('mentionne CORS et l\'URL pour ClientException', () {
      final message = BackendDiagnostics.describeNetworkError(
        http.ClientException('Failed to fetch'),
        attemptedUrl: 'https://api.example.com/api/auth/admin/exchange',
      );
      expect(message, contains('Backend injoignable'));
      expect(message, contains('CORS'));
      expect(message, contains('api.example.com'));
    });

    test('fallback generique pour erreur inconnue', () {
      final message = BackendDiagnostics.describeNetworkError(Exception('x'));
      expect(message, contains('Reessayez plus tard'));
    });
  });
}
