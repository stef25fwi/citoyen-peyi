import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionCommune {
  const AuthSessionCommune({
    required this.name,
    this.code,
    this.codePostal,
  });

  final String name;
  final String? code;
  final String? codePostal;

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'codePostal': codePostal,
      };

  static AuthSessionCommune? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    final name = raw['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      return null;
    }

    return AuthSessionCommune(
      name: name,
      code: raw['code'] as String?,
      codePostal: raw['codePostal'] as String?,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.role,
    required this.admin,
    required this.controller,
    required this.mode,
    this.adminScope,
    this.customToken,
    this.id,
    this.code,
    this.label,
    this.commune,
  });

  final String role;
  final bool admin;
  final bool controller;
  final String mode;
  final String? adminScope;
  final String? customToken;
  final String? id;
  final String? code;
  final String? label;
  final AuthSessionCommune? commune;

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => admin || role == 'admin' || role == 'super_admin';
  bool get isController => controller || role == 'controller';
  bool get isAuthenticated => isAdmin || isController;

  String get modeLabel => mode == 'fallback' ? 'fallback' : 'secure';

  bool hasAnyRole(Iterable<String> roles) {
    for (final roleName in roles) {
      if (roleName == 'super_admin' && isSuperAdmin) return true;
      if (roleName == 'admin' && isAdmin) return true;
      if (roleName == 'controller' && isController) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'admin': admin,
        'controller': controller,
        'mode': mode,
        'adminScope': adminScope,
        'customToken': customToken,
        'id': id,
        'code': code,
        'label': label,
        'commune': commune?.toJson(),
      };

  static AuthSession fromJson(Map<String, dynamic> json) {
    return AuthSession(
      role: json['role'] as String? ?? 'guest',
      admin: json['admin'] as bool? ?? false,
      controller: json['controller'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'fallback',
      adminScope: json['adminScope'] as String?,
      customToken: json['customToken'] as String?,
      id: json['id'] as String?,
      code: json['code'] as String?,
      label: json['label'] as String?,
      commune: AuthSessionCommune.fromJson(json['commune']),
    );
  }
}

class AuthSessionStore {
  AuthSessionStore._();

  static const _storageKey = 'flutter_admin_session_v1';
  static final AuthSessionStore instance = AuthSessionStore._();

  SharedPreferences? _preferences;
  AuthSession? _currentSession;

  AuthSession? get currentSession => _currentSession;

  bool get isAdminAuthenticated => _currentSession?.isAdmin == true;
  bool get isControllerAuthenticated => _currentSession?.isController == true;

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    final raw = _preferences?.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _currentSession = null;
      return;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _currentSession = AuthSession.fromJson(json);
    } catch (_) {
      _currentSession = null;
    }
  }

  Future<void> save(AuthSession session) async {
    _preferences ??= await SharedPreferences.getInstance();
    _currentSession = session;
    await _preferences?.setString(_storageKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    _preferences ??= await SharedPreferences.getInstance();
    _currentSession = null;
    await _preferences?.remove(_storageKey);
  }
}
