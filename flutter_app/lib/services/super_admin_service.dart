import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'auth_session_store.dart';
import 'backend_diagnostics.dart';
import 'debug_log_service.dart';
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
    this.referenceEmail = '',
    required this.accessKey,
    required this.createdAt,
    this.attachedToExistingCommune = false,
  });

  final String id;
  final String label;
  final String communeName;
  final String? communeCode;
  final String? codePostal;
  final String referenceEmail;
  final String accessKey;
  final String createdAt;

  /// Vrai lorsque la creation a rattache ce profil a une commune deja
  /// existante (meme code INSEE) plutot que d'en creer une variante. Transitoire
  /// (non persiste), renseigne uniquement a la creation.
  final bool attachedToExistingCommune;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'communeName': communeName,
        'communeCode': communeCode,
        'codePostal': codePostal,
        'referenceEmail': referenceEmail,
        'createdAt': createdAt,
      };

  AdminProfileModel withoutAccessKey() => AdminProfileModel(
        id: id,
        label: label,
        communeName: communeName,
        communeCode: communeCode,
        codePostal: codePostal,
        referenceEmail: referenceEmail,
        accessKey: '',
        createdAt: createdAt,
      );

  static AdminProfileModel? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'] as String?;
    final label = raw['label'] as String?;
    final communeName = raw['communeName'] as String?;
    final createdAt = raw['createdAt'] as String?;
    if (id == null ||
        label == null ||
        communeName == null ||
        createdAt == null) {
      return null;
    }
    return AdminProfileModel(
      id: id,
      label: label,
      communeName: communeName,
      communeCode: raw['communeCode'] as String?,
      codePostal: raw['codePostal'] as String?,
      referenceEmail: raw['referenceEmail'] as String? ?? '',
      accessKey: '',
      createdAt: createdAt,
    );
  }
}

// ---------- Service ----------

class SuperAdminService {
  SuperAdminService._();

  static final SuperAdminService instance = SuperAdminService._();

  Future<String?> _superAdminIdToken() async {
    try {
      final token = await FirebaseAuthService.instance.requireFreshIdToken();
      if (token.isNotEmpty) {
        return token;
      }
    } catch (error) {
      _debugLog('Echec refresh idToken local: $error');
    }
    return null;
  }

  Future<String> _firebaseIdTokenFromCustomToken(String customToken) async {
    try {
      final token =
          await FirebaseAuthService.instance.signInWithCustomToken(customToken);
      _debugLog('Token Firebase direct present: ${token.isNotEmpty}');
      return token;
    } catch (error) {
      _debugLog('FirebaseAuth custom token direct failure: $error');
      _debugLog(
          'Authentification Firebase refusée. Tentative de connexion sécurisée alternative…');
    }

    try {
      final token = await FirebaseAuthService.instance
          .exchangeCustomTokenViaRest(customToken);
      _debugLog('Token Firebase REST present: ${token.isNotEmpty}');
      return token;
    } catch (error) {
      _debugLog('REST fallback failure: $error');
      throw const SuperAdminAuthException(
        'Authentification Firebase refusée. Tentative de connexion sécurisée alternative impossible. Reconnectez-vous.',
      );
    }
  }

  static const _profilesKey = 'super_admin_profiles_v1';
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();
  String? get runtimeSuperAdminKey =>
      AuthSessionStore.instance.currentSession?.isSuperAdmin == true
          ? 'secure-session'
          : null;

  void _debugLog(String message) {
    // Toujours capture dans le journal de diagnostic (visible via le bouton
    // debug), y compris en build release ou debugPrint est inactif.
    DebugLogService.instance.log('[SuperAdminService]', message);
  }

  void clearRuntimeSuperAdminKey() {
    // Aucune cle runtime persistante apres authentification.
  }

  /// Authenticate as super admin. La cle saisie est envoyee au backend comme
  /// header runtime et n'est jamais compilee dans Flutter.
  Future<void> signIn(String accessKey) async {
    final trimmed = accessKey.trim();
    _debugLog('signIn: debut (cle ${trimmed.length} caracteres)');
    if (trimmed.isEmpty) {
      throw const SuperAdminAuthException('Cle super admin requise.');
    }

    final configIssue = BackendDiagnostics.describeConfigIssue();
    if (configIssue != null) {
      _debugLog('signIn: config backend invalide -> $configIssue');
      throw SuperAdminAuthException(configIssue);
    }

    final url = '${AppConfig.apiBaseUrl}/api/auth/super/exchange';
    _debugLog('signIn: POST $url');
    final appCheckToken =
        await FirebaseAuthService.instance.currentAppCheckToken();
    _debugLog(
        'signIn: App Check token ${appCheckToken == null || appCheckToken.isEmpty ? "absent" : "present (${appCheckToken.length} car.)"}');
    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'x-super-admin-key': trimmed,
              if (appCheckToken != null && appCheckToken.isNotEmpty)
                'X-Firebase-AppCheck': appCheckToken,
            },
            body: jsonEncode(const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      _debugLog('signIn: ECHEC reseau POST exchange -> $error');
      throw SuperAdminAuthException(
          BackendDiagnostics.describeNetworkError(error, attemptedUrl: url));
    }

    _debugLog('signIn: reponse exchange HTTP ${response.statusCode}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final bodyPreview = response.body.length > 300
          ? '${response.body.substring(0, 300)}…'
          : response.body;
      _debugLog('signIn: corps erreur exchange -> $bodyPreview');
      throw SuperAdminAuthException(_readError(response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final customToken = payload['customToken'] as String?;

    if (customToken == null || customToken.isEmpty) {
      _debugLog('signIn: customToken manquant dans la reponse');
      throw const SuperAdminAuthException(
          'Reponse backend invalide (customToken manquant).');
    }
    _debugLog('signIn: customToken recu (${customToken.length} car.), '
        'echange Firebase…');

    await _firebaseIdTokenFromCustomToken(customToken);
    _debugLog('signIn: idToken Firebase obtenu, sauvegarde session…');

    await AuthSessionStore.instance.save(AuthSession(
      role: 'super_admin',
      admin: true,
      controller: false,
      mode: 'secure',
      adminScope: 'global',
      label: 'Super Administrateur',
    ));
    _debugLog('signIn: SUCCES — session super admin enregistree');
  }

  /// Retourne la liste des profils admin via le backend (preferred) ou via
  /// le cache local en lecture seule.
  Future<List<AdminProfileModel>> loadProfiles() async {
    String? token;
    try {
      token = await _superAdminIdToken();
    } catch (error) {
      _debugLog('loadProfiles: token indisponible: $error');
    }

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/api/admins'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 12));
        _debugLog('loadProfiles HTTP ${response.statusCode}');
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
                    referenceEmail: item['referenceEmail'] as String? ?? '',
                    accessKey: '',
                    createdAt: item['createdAt']?.toString() ??
                        DateTime.now().toIso8601String(),
                  ))
              .where((profile) => profile.id.isNotEmpty)
              .toList();
          await _saveProfiles(list);
          return list;
        }
        throw SuperAdminAuthException(_readError(response.body));
      } on SuperAdminAuthException {
        rethrow;
      } catch (error) {
        _debugLog('loadProfiles fallback cache, erreur: $error');
        // On retombe sur le cache local plutot que de bloquer l'UI.
      }
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
    String? referenceEmail,
  }) async {
    final trimmedLabel = label.trim();
    final trimmedCommuneName = communeName.trim();
    final trimmedCommuneCode = communeCode?.trim() ?? '';
    final trimmedCodePostal = codePostal?.trim() ?? '';
    final trimmedEmail = referenceEmail?.trim() ?? '';

    if (trimmedCommuneName.isEmpty) {
      throw const SuperAdminAuthException('Le nom de la commune est requis.');
    }
    if (trimmedCodePostal.isEmpty) {
      throw const SuperAdminAuthException('Le code postal est requis.');
    }
    if (trimmedCommuneCode.isEmpty) {
      throw const SuperAdminAuthException('Le code INSEE est requis.');
    }
    if (trimmedLabel.isEmpty) {
      throw const SuperAdminAuthException('Le libelle du profil est requis.');
    }

    _debugLog('Tentative de création profil administrateur.');

    final response = await _authorizedPost('/api/admins', {
      'label': trimmedLabel,
      'communeName': trimmedCommuneName,
      'communeCode': trimmedCommuneCode,
      'codePostal': trimmedCodePostal,
      if (trimmedEmail.isNotEmpty) 'referenceEmail': trimmedEmail,
    });

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final profile = AdminProfileModel(
      id: payload['id'] as String? ?? _generateId(),
      label: payload['label'] as String? ?? trimmedLabel,
      communeName: payload['communeName'] as String? ?? trimmedCommuneName,
      communeCode: payload['communeCode'] as String?,
      codePostal: payload['codePostal'] as String?,
      referenceEmail: payload['referenceEmail'] as String? ?? trimmedEmail,
      accessKey: payload['accessKey'] as String? ?? '',
      createdAt: DateTime.now().toIso8601String(),
      attachedToExistingCommune:
          payload['attachedToExistingCommune'] as bool? ?? false,
    );

    final profiles = await loadProfiles();
    profiles.add(profile.withoutAccessKey());
    await _saveProfiles(profiles);
    return profile;
  }

  /// Regenere la cle d'acces d'un admin communal. Les cles d'origine sont
  /// hachees (irrecuperables) : le backend en emet une nouvelle, retournee une
  /// seule fois, et invalide l'ancienne.
  Future<String> regenerateAdminKey(String id) async {
    final response =
        await _authorizedPost('/api/admins/$id/regenerate', const {});
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final key = payload['accessKey'] as String?;
    if (key == null || key.isEmpty) {
      throw const SuperAdminAuthException('Cle regeneree indisponible.');
    }
    return key;
  }

  /// Supprime un profil admin par ID via l'API backend.
  Future<void> deleteProfile(String id) async {
    await _authorizedDelete('/api/admins/$id');
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == id);
    await _saveProfiles(profiles);
  }

  Future<void> bulkDeleteProfiles(List<String> ids) async {
    final uniqueIds = ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueIds.isEmpty) return;
    await _authorizedPost('/api/admins/bulk-delete', {'ids': uniqueIds});
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => uniqueIds.contains(p.id));
    await _saveProfiles(profiles);
  }

  Future<http.Response> _authorizedPost(String path, Object body) async {
    final configIssue = BackendDiagnostics.describeConfigIssue();
    if (configIssue != null) {
      throw SuperAdminAuthException(configIssue);
    }

    // La cle n'est plus requise apres login : le token Firebase (claim
    // super_admin) autorise cote backend. La cle reste envoyee si presente.
    final url = '${AppConfig.apiBaseUrl}$path';
    _debugLog('Endpoint appelé: $url');
    if (path == '/api/admins') {
      _debugLog('/api/admins appelé');
    }

    late String token;
    try {
      final resolvedToken = await _superAdminIdToken();
      if (resolvedToken == null || resolvedToken.isEmpty) {
        throw const SuperAdminAuthException(
            'Session super administrateur expirée ou non autorisée. Reconnectez-vous.');
      }
      token = resolvedToken;
      _debugLog('Token Firebase present: ${token.isNotEmpty}');
    } on SuperAdminAuthException {
      rethrow;
    } catch (error) {
      _debugLog('Erreur catchée: $error');
      throw SuperAdminAuthException(
          BackendDiagnostics.describeNetworkError(error, attemptedUrl: url));
    }

    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
      _debugLog('Statut HTTP: ${response.statusCode}');
    } catch (error) {
      _debugLog('Erreur catchée: $error');
      throw SuperAdminAuthException(
          BackendDiagnostics.describeNetworkError(error, attemptedUrl: url));
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SuperAdminAuthException(
          'Session super administrateur expirée ou non autorisée. Reconnectez-vous.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminAuthException(_readError(response.body));
    }
    return response;
  }

  Future<void> _authorizedDelete(String path) async {
    final token = await _superAdminIdToken();
    if (token == null) {
      throw const SuperAdminAuthException(
          'Session super administrateur expiree, reconnectez-vous.');
    }
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 12));
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
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return payload['message'] as String? ??
          payload['error'] as String? ??
          'Connexion impossible.';
    } catch (_) {
      return 'Connexion impossible.';
    }
  }
}
