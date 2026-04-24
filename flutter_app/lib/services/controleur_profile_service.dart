import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Profil contrôleur stocké localement.
class ControleurProfileModel {
  const ControleurProfileModel({
    required this.id,
    required this.code,
    required this.label,
    required this.communeName,
    this.communeCode,
    this.codePostal,
    required this.createdAt,
    this.usedAt,
  });

  final String id;
  final String code;
  final String label;
  final String communeName;
  final String? communeCode;
  final String? codePostal;
  final String createdAt;
  final String? usedAt;

  bool get hasBeenUsed => usedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
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
    final code = raw['code'] as String?;
    final label = raw['label'] as String?;
    final createdAt = raw['createdAt'] as String?;
    if (code == null || label == null) return null;

    final commune = raw['commune'] as Map<String, dynamic>?;

    return ControleurProfileModel(
      id: raw['id'] as String? ?? code,
      code: code,
      label: label,
      communeName: commune?['name'] as String? ?? '',
      communeCode: commune?['code'] as String?,
      codePostal: commune?['codePostal'] as String?,
      createdAt: createdAt ?? DateTime.now().toIso8601String(),
      usedAt: raw['usedAt'] as String?,
    );
  }
}

class ControleurProfileService {
  ControleurProfileService._();

  static final ControleurProfileService instance = ControleurProfileService._();

  // Même clé que ControllerAuthService pour compatibilité fallback
  static const _storageKey = 'controleur_codes_v1';
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();

  Future<List<ControleurProfileModel>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(ControleurProfileModel.fromJson)
          .whereType<ControleurProfileModel>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ControleurProfileModel> createProfile({
    required String label,
    required String communeName,
    String? communeCode,
    String? codePostal,
  }) async {
    if (label.trim().isEmpty) throw Exception('Le libelle est requis.');
    if (communeName.trim().isEmpty) throw Exception('La commune est requise.');

    final profiles = await loadProfiles();

    final profile = ControleurProfileModel(
      id: _segment(12).toLowerCase(),
      code: 'CTRL-${_segment(8)}',
      label: label.trim(),
      communeName: communeName.trim(),
      communeCode: communeCode?.trim().isEmpty == true ? null : communeCode?.trim(),
      codePostal: codePostal?.trim().isEmpty == true ? null : codePostal?.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    profiles.add(profile);
    await _save(profiles);
    return profile;
  }

  Future<void> deleteProfile(String code) async {
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.code == code);
    await _save(profiles);
  }

  Future<void> _save(List<ControleurProfileModel> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  String _segment(int length) => List.generate(
        length,
        (_) => _alphabet[_random.nextInt(_alphabet.length)],
      ).join();
}
