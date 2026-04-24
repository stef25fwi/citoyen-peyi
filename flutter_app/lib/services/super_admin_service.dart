import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_session_store.dart';
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
        'accessKey': accessKey,
        'createdAt': createdAt,
      };

  static AdminProfileModel? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'] as String?;
    final label = raw['label'] as String?;
    final communeName = raw['communeName'] as String?;
    final accessKey = raw['accessKey'] as String?;
    final createdAt = raw['createdAt'] as String?;
    if (id == null || label == null || communeName == null || accessKey == null || createdAt == null) {
      return null;
    }
    return AdminProfileModel(
      id: id,
      label: label,
      communeName: communeName,
      communeCode: raw['communeCode'] as String?,
      codePostal: raw['codePostal'] as String?,
      accessKey: accessKey,
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

  /// Authenticate as super admin. En mode fallback, vérifie contre SUPER_ADMIN_KEY
  /// si défini, sinon accepte n'importe quelle clé (mode démo).
  Future<void> signIn(String accessKey) async {
    final trimmed = accessKey.trim();
    if (trimmed.isEmpty) {
      throw const SuperAdminAuthException('Cle super admin requise.');
    }

    final isLocalMode = AppConfig.apiBaseUrl.isEmpty ||
        AppConfig.apiBaseUrl.contains('localhost') ||
        AppConfig.apiBaseUrl.contains('127.0.0.1');

    if (isLocalMode) {
      final expected = AppConfig.superAdminKey;
      if (expected.isNotEmpty && trimmed != expected) {
        throw const SuperAdminAuthException('Cle super admin invalide.');
      }
      await AuthSessionStore.instance.save(AuthSession(
        role: 'super_admin',
        admin: true,
        controller: false,
        mode: 'fallback',
        adminScope: 'global',
        label: 'Super Administrateur',
      ));
      return;
    }

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/auth/super/exchange'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'accessKey': trimmed}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminAuthException(_readError(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final customToken = payload['customToken'] as String?;

    if (customToken != null && customToken.isNotEmpty) {
      await FirebaseAuthService.instance.signInWithCustomToken(customToken);
    }

    await AuthSessionStore.instance.save(AuthSession(
      role: 'super_admin',
      admin: true,
      controller: false,
      mode: 'secure',
      adminScope: 'global',
      customToken: customToken,
      label: 'Super Administrateur',
    ));
  }

  /// Retourne la liste des profils admin créés localement.
  Future<List<AdminProfileModel>> loadProfiles() async {
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

  /// Crée un profil admin rattaché à une commune et génère une clé d'accès.
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

    final profiles = await loadProfiles();

    final profile = AdminProfileModel(
      id: _generateId(),
      label: label.trim(),
      communeName: communeName.trim(),
      communeCode: communeCode?.trim().isEmpty == true ? null : communeCode?.trim(),
      codePostal: codePostal?.trim().isEmpty == true ? null : codePostal?.trim(),
      accessKey: _generateAccessKey(),
      createdAt: DateTime.now().toIso8601String(),
    );

    profiles.add(profile);
    await _saveProfiles(profiles);
    return profile;
  }

  /// Supprime un profil admin par ID.
  Future<void> deleteProfile(String id) async {
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == id);
    await _saveProfiles(profiles);
  }

  Future<void> _saveProfiles(List<AdminProfileModel> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  String _generateAccessKey() {
    final part1 = _randomSegment(8);
    final part2 = _randomSegment(4);
    return 'ADM-$part1-$part2';
  }

  String _generateId() => _randomSegment(16).toLowerCase();

  String _randomSegment(int length) => List.generate(
        length,
        (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
      ).join();

  String _readError(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['message'] as String? ??
          'Connexion impossible.';
    } catch (_) {
      return 'Connexion impossible.';
    }
  }
}
