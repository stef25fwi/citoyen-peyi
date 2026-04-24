import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BrowserStorageService {
  BrowserStorageService._();

  static final BrowserStorageService instance = BrowserStorageService._();

  SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async {
    _preferences ??= await SharedPreferences.getInstance();
    return _preferences!;
  }

  Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) {
        return const <Map<String, dynamic>>[];
      }

      return parsed.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(value));
  }

  Future<Map<String, dynamic>?> readJsonMap(String key) async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) {
        return null;
      }

      return parsed;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJsonMap(String key, Map<String, dynamic> value) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(value));
  }
}
