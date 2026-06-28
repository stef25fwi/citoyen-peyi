import 'browser_storage_service.dart';

class CitizenCommuneContext {
  const CitizenCommuneContext({
    required this.communeId,
    required this.communeName,
  });

  final String communeId;
  final String communeName;

  bool get hasScope => communeId.isNotEmpty || communeName.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'communeId': communeId,
        'communeName': communeName,
      };

  static CitizenCommuneContext? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final communeId = (json['communeId'] as String? ?? '').trim();
    final communeName = (json['communeName'] as String? ?? '').trim();
    if (communeId.isEmpty && communeName.isEmpty) return null;
    return CitizenCommuneContext(
      communeId: communeId,
      communeName: communeName,
    );
  }
}

class CitizenCommuneStore {
  CitizenCommuneStore._();

  static final CitizenCommuneStore instance = CitizenCommuneStore._();

  static const _storageKey = 'citizen_commune_context_v1';

  CitizenCommuneContext? _cachedContext;

  CitizenCommuneContext? get cachedContext => _cachedContext;

  Future<CitizenCommuneContext?> currentContext() async {
    if (_cachedContext != null) return _cachedContext;
    _cachedContext = CitizenCommuneContext.fromJson(
      await BrowserStorageService.instance.readJsonMap(_storageKey),
    );
    return _cachedContext;
  }

  Future<void> save({
    required String communeId,
    required String communeName,
  }) async {
    final context = CitizenCommuneContext(
      communeId: communeId.trim(),
      communeName: communeName.trim(),
    );
    if (!context.hasScope) return;
    _cachedContext = context;
    try {
      await BrowserStorageService.instance.writeJsonMap(
        _storageKey,
        context.toJson(),
      );
    } catch (_) {
      // Cache is already set above; storage failure is non-fatal.
    }
  }
}
