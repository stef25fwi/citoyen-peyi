import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_session_store.dart';
import 'backend_diagnostics.dart';
import 'firebase_auth_service.dart';

class SuperAdminAuthException implements Exception {
  const SuperAdminAuthException(this.message);

  final String message;
}

// ---------- Admin profile model ----------

class AdminProfileModel {
  const AdminProfileModel({
    required this.id,
    required this.label,
    required this.communeName,
    this.communeCode,
    this.codePostal,
    required this.accessKey,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String communeName;
  final String? communeCode;
  final String? codePostal;
  final String accessKey;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'communeName': communeName,
        'communeCode': communeCode,
        'codePostal': codePostal,
        'createdAt': createdAt,
      };

  AdminProfileModel withoutAccessKey() => AdminProfileModel(
        id: id,
        label: label,
        communeName: communeName,
        communeCode: communeCode,
        codePostal: codePostal,
        accessKey: '',
        createdAt: createdAt,
      );

  static AdminProfileModel? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'] as String?;
    final label = raw['label'] as String?;
    final communeName = raw['communeName'] as String?;
    final createdAt = raw['createdAt'] as String?;
    if (id == null || label == null || communeName == null || createdAt == null) {
      return null;
    }
    return AdminProfileModel(
      id: id,
      label: label,
      communeName: communeName,
      communeCode: raw['communeCode'] as String?,
      codePostal: raw['codePostal'] as String?,
      accessKey: '',
      createdAt: createdAt,
    );
  }
}

// ---------- Service ----------

class SuperAdminService {
  SuperAdminService._();

  static final SuperAdminService instance = SuperAdminService._();

  static const _profilesKey = 'super_admin_profiles_v1';
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();
  String? _runtimeSuperAdminKey;

  String? get runtimeSuperAdminKey => _runtimeSuperAdminKey;

  void clearRuntimeSuperAdminKey() {
    _runtimeSuperAdminKey = null;
  }

  /// Authenticate as super admin. La cle saisie est envoyee au backend comme
  /// header runtime et n'est jamais compilee dans Flutter.
  Future<void> signIn(String accessKey) async {
    final trimmed = accessKey.trim();
    if (trimmed.isEmpty) {
      throw const SuperAdminAuthException('Cle super admin requise.');
    }

    final configIssue = BackendDiagnostics.describeConfigIssue();
    if (configIssue != null) {
      throw SuperAdminAuthException(configIssue);
    }

    final url = '${AppConfig.apiBaseUrl}/api/auth/super/exchange';
    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'x-super-admin-key': trimmed,
            },
            body: jsonEncode(const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      throw SuperAdminAuthException(
          BackendDiagnostics.describeNetworkError(error, attemptedUrl: url));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminAuthException(_readError(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final customToken = payload['customToken'] as String?;

    if (customToken == null || customToken.isEmpty) {
      throw const SuperAdminAuthException('Reponse backend invalide (customToken manquant).');
    }

    await FirebaseAuthService.instance.signInWithCustomToken(customToken);

    _runtimeSuperAdminKey = trimmed;

    await AuthSessionStore.instance.save(AuthSession(
      role: 'super_admin',
      admin: true,
      controller: false,
      mode: 'secure',
      adminScope: 'global',
      label: 'Super Administrateur',
    ));
  }

  /// Retourne la liste des profils admin via le backend (preferred) ou via
  /// le cache local en lecture seule.
  Future<List<AdminProfileModel>> loadProfiles() async {
    try {
      final superKey = _runtimeSuperAdminKey;
      final token = await FirebaseAuthService.instance.currentIdToken();
      if (superKey != null && superKey.isNotEmpty && token != null) {
        final response = await http
            .get(
              Uri.parse('${AppConfig.apiBaseUrl}/api/admins'),
              headers: {
                'Authorization': 'Bearer $token',
                'x-super-admin-key': superKey,
              },
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final payload = jsonDecode(response.body) as Map<String, dynamic>;
          final list = (payload['admins'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map((item) => AdminProfileModel(
                    id: item['id'] as String? ?? '',
                    label: item['label'] as String? ?? '',
                    communeName: item['communeName'] as String? ?? '',
                    communeCode: item['communeCode'] as String?,
                    codePostal: item['codePostal'] as String?,
                    accessKey: '',
                    createdAt: item['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
                  ))
              .where((profile) => profile.id.isNotEmpty)
              .toList();
          return list;
        }
      }
    } catch (_) {
      // Tomber vers le cache local.
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(AdminProfileModel.fromJson)
          .whereType<AdminProfileModel>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Crée un profil admin rattaché à une commune via l'API backend (la clé
  /// d'accès est généree côté serveur et n'est retournee qu'une seule fois).
  Future<AdminProfileModel> createAdminProfile({
    required String label,
    required String communeName,
    String? communeCode,
    String? codePostal,
  }) async {
    if (label.trim().isEmpty) {
      throw const SuperAdminAuthException('Le libelle du profil est requis.');
    }
    if (communeName.trim().isEmpty) {
      throw const SuperAdminAuthException('Le nom de la commune est requis.');
    }

    final response = await _authorizedPost('/api/admins', {
      'label': label.trim(),
      'communeName': communeName.trim(),
      'communeCode': communeCode?.trim(),
      'codePostal': codePostal?.trim(),
    });

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final profile = AdminProfileModel(
      id: payload['id'] as String? ?? _generateId(),
      label: payload['label'] as String? ?? label.trim(),
      communeName: payload['communeName'] as String? ?? communeName.trim(),
      communeCode: payload['communeCode'] as String?,
      codePostal: payload['codePostal'] as String?,
      accessKey: payload['accessKey'] as String? ?? '',
      createdAt: DateTime.now().toIso8601String(),
    );

    final profiles = await loadProfiles();
    profiles.add(profile.withoutAccessKey());
    await _saveProfiles(profiles);
    return profile;
  }

  /// Supprime un profil admin par ID via l'API backend.
  Future<void> deleteProfile(String id) async {
    await _authorizedDelete('/api/admins/$id');
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == id);
    await _saveProfiles(profiles);
  }

  Future<http.Response> _authorizedPost(String path, Object body) async {
    final superKey = _runtimeSuperAdminKey;
    if (superKey == null || superKey.isEmpty) {
      throw const SuperAdminAuthException('Session super admin expiree, reconnectez-vous.');
    }
    final token = await FirebaseAuthService.instance.currentIdToken();
    if (token == null) {
      throw const SuperAdminAuthException('Session Firebase manquante, reconnectez-vous.');
    }
    final response = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'x-super-admin-key': superKey,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminAuthException(_readError(response.body));
    }
    return response;
  }

  Future<void> _authorizedDelete(String path) async {
    final superKey = _runtimeSuperAdminKey;
    if (superKey == null || superKey.isEmpty) {
      throw const SuperAdminAuthException('Session super admin expiree, reconnectez-vous.');
    }
    final token = await FirebaseAuthService.instance.currentIdToken();
    if (token == null) {
      throw const SuperAdminAuthException('Session Firebase manquante, reconnectez-vous.');
    }
    final response = await http
        .delete(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: {
            'Authorization': 'Bearer $token',
            'x-super-admin-key': superKey,
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminAuthException(_readError(response.body));
    }
  }

  Future<void> _saveProfiles(List<AdminProfileModel> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((p) => p.withoutAccessKey().toJson()).toList()),
    );
  }

  String _generateId() => List.generate(
        16,
        (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
      ).join().toLowerCase();

  String _readError(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['message'] as String? ??
          'Connexion impossible.';
    } catch (_) {
      return 'Connexion impossible.';
    }
  }
}
