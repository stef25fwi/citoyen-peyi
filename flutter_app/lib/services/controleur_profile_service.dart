import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'firebase_auth_service.dart';

/// Profil contrôleur géré côté backend uniquement.
class ControleurProfileModel {
  const ControleurProfileModel({
    required this.id,
    required this.code,
    required this.label,
    required this.communeName,
    this.communeCode,
    this.codePostal,
    this.displayCodeMasked = '',
    required this.createdAt,
    this.usedAt,
  });

  final String id;
  final String code;
  final String label;
  final String communeName;
  final String? communeCode;
  final String? codePostal;
  final String displayCodeMasked;
  final String createdAt;
  final String? usedAt;

  bool get hasBeenUsed => usedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'displayCodeMasked': displayCodeMasked,
        'label': label,
        'commune': {
          'name': communeName,
          'code': communeCode,
          'codePostal': codePostal,
        },
        'createdAt': createdAt,
        'usedAt': usedAt,
      };

  static ControleurProfileModel? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final code = raw['code'] as String? ?? '';
    final label = raw['label'] as String?;
    final id = raw['id'] as String? ?? code;
    if (id.isEmpty || label == null) return null;

    final commune = raw['commune'] as Map<String, dynamic>?;

    return ControleurProfileModel(
      id: id,
      code: code,
      label: label,
      communeName: commune?['name'] as String? ?? '',
      communeCode: commune?['code'] as String?,
      codePostal: commune?['codePostal'] as String?,
      displayCodeMasked: raw['displayCodeMasked'] as String? ??
          (code.isEmpty
              ? ''
              : '${code.substring(0, 5)}••••${code.substring(code.length - 2)}'),
      createdAt:
          raw['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      usedAt: raw['usedAt']?.toString(),
    );
  }
}

class ControleurProfileException implements Exception {
  const ControleurProfileException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ControleurProfileService {
  ControleurProfileService._();

  static final ControleurProfileService instance = ControleurProfileService._();

  Future<List<ControleurProfileModel>> loadProfiles() async {
    final response = await _authorizedRequest('GET', '/api/controllers');
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['controllers'] as List<dynamic>? ?? const [])
        .map(ControleurProfileModel.fromJson)
        .whereType<ControleurProfileModel>()
        .toList();
  }

  Future<ControleurProfileModel> createProfile({
    required String label,
    required String communeName,
    String? communeCode,
    String? codePostal,
  }) async {
    if (label.trim().isEmpty) {
      throw const ControleurProfileException('Le libellé est requis.');
    }
    if (communeName.trim().isEmpty) {
      throw const ControleurProfileException('La commune est requise.');
    }

    final response =
        await _authorizedRequest('POST', '/api/controllers', body: {
      'label': label.trim(),
      'communeName': communeName.trim(),
      if (communeCode != null && communeCode.trim().isNotEmpty)
        'communeCode': communeCode.trim(),
      if (codePostal != null && codePostal.trim().isNotEmpty)
        'codePostal': codePostal.trim(),
    });

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final controller = ControleurProfileModel.fromJson(payload['controller']);
    if (controller == null) {
      throw const ControleurProfileException('Réponse backend invalide.');
    }
    return controller;
  }

  Future<void> deleteProfile(String id) async {
    await _authorizedRequest('DELETE', '/api/controllers/$id');
  }

  Future<http.Response> _authorizedRequest(String method, String path,
      {Object? body}) async {
    final token = await FirebaseAuthService.instance.currentIdToken();
    if (token == null || token.isEmpty) {
      throw const ControleurProfileException(
          'Session Firebase manquante, reconnectez-vous.');
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 10));
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(const Duration(seconds: 12));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 10));
          break;
        default:
          throw ControleurProfileException(
              'Méthode HTTP non supportée: $method');
      }
    } catch (error) {
      if (error is ControleurProfileException) rethrow;
      throw const ControleurProfileException(
          'Backend injoignable. Réessayez plus tard.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Opération impossible.';
      try {
        message = (jsonDecode(response.body) as Map<String, dynamic>)['message']
                as String? ??
            message;
      } catch (_) {}
      throw ControleurProfileException(message);
    }
    return response;
  }
}
