import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth_session_store.dart';
import 'browser_storage_service.dart';
import 'citizen_commune_store.dart';
import 'firestore_data_service.dart';

/// Tracks published polls not yet seen by the current citizen commune.
/// Call [startListening] on app boot / nav-bar build.
/// Call [markAllSeen] when the user lands on the vote/access page.
class NewPollBadgeService {
  NewPollBadgeService._();

  static final NewPollBadgeService instance = NewPollBadgeService._();

  static const _seenKey = 'seen_poll_ids_v1';
  static const _pollCollection = 'polls';

  final ValueNotifier<bool> hasNew = ValueNotifier<bool>(false);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _lastScopeKey;
  _CommuneScope? _lastScope;

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<_CommuneScope?> _communeScope() async {
    final session = AuthSessionStore.instance.currentSession;
    final sessionCommuneId = session?.commune?.code?.trim() ?? '';
    final sessionCommuneName = session?.commune?.name.trim() ?? '';
    if (sessionCommuneId.isNotEmpty || sessionCommuneName.isNotEmpty) {
      return _CommuneScope(
        communeId: sessionCommuneId,
        communeName: sessionCommuneName,
      );
    }

    final citizenContext = await CitizenCommuneStore.instance.currentContext();
    if (citizenContext == null || !citizenContext.hasScope) return null;
    return _CommuneScope(
      communeId: citizenContext.communeId,
      communeName: citizenContext.communeName,
    );
  }

  Future<Set<String>> _seenIds() async {
    final raw = await BrowserStorageService.instance.readJsonList(_seenKey);
    return raw.map((m) => m['id'] as String?).whereType<String>().toSet();
  }

  Query<Map<String, dynamic>> _queryForScope(
    FirebaseFirestore db,
    _CommuneScope scope,
  ) {
    final collection = db.collection(_pollCollection);
    if (scope.communeId.isNotEmpty) {
      return collection.where('communeId', isEqualTo: scope.communeId);
    }
    return collection.where('communeName', isEqualTo: scope.communeName);
  }

  bool _isVisiblePoll(Map<String, dynamic> data) {
    final status = (data['status'] as String? ?? '').trim().toLowerCase();
    final now = DateTime.now();
    final scheduledPublishDate = _readDate(
      data['scheduledPublishDate'] ?? data['publishDate'],
    );
    final scheduledIsDue = status == 'scheduled' &&
        scheduledPublishDate != null &&
        !scheduledPublishDate.isAfter(now);

    if (!['active', 'open'].contains(status) && !scheduledIsDue) {
      return false;
    }

    final opensAt = _readDate(data['opensAt'] ?? data['openDate']);
    final closesAt = _readDate(data['closesAt'] ?? data['closeDate']);
    if (opensAt != null && opensAt.isAfter(now)) return false;
    if (closesAt != null && closesAt.isBefore(now)) return false;
    return true;
  }

  DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.length == 10 ? '${raw}T00:00:00' : raw);
  }

  Future<void> _refreshFromDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final liveIds = docs
        .where((doc) => _isVisiblePoll(doc.data()))
        .map((doc) => doc.id)
        .toSet();
    final seen = await _seenIds();
    hasNew.value = liveIds.difference(seen).isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> _visiblePollIdsForScope(
    FirebaseFirestore db,
    _CommuneScope scope,
  ) async {
    final snapshot = await _queryForScope(db, scope).limit(100).get();
    return snapshot.docs
        .where((doc) => _isVisiblePoll(doc.data()))
        .map((doc) => <String, dynamic>{'id': doc.id})
        .toList();
  }

  // ── public API ───────────────────────────────────────────────────────────

  Future<void> startListening() async {
    final db = FirestoreDataService.instance;
    if (db == null) {
      await _subscription?.cancel();
      _subscription = null;
      _lastScopeKey = null;
      hasNew.value = false;
      return;
    }

    final scope = await _communeScope();
    if (scope == null || !scope.hasScope) {
      await _subscription?.cancel();
      _subscription = null;
      _lastScopeKey = null;
      hasNew.value = false;
      return;
    }

    _lastScope = scope;
    if (_subscription != null && _lastScopeKey == scope.key) {
      await check();
      return;
    }

    await _subscription?.cancel();
    _lastScopeKey = scope.key;
    _subscription = _queryForScope(db, scope).limit(100).snapshots().listen(
          (snapshot) => unawaited(_refreshFromDocs(snapshot.docs)),
          onError: (_) => hasNew.value = false,
        );
    await check();
  }

  /// Queries Firestore for published polls of the user's commune.
  Future<void> check() async {
    final db = FirestoreDataService.instance;
    if (db == null) {
      hasNew.value = false;
      return;
    }

    final scope = await _communeScope();
    if (scope == null || !scope.hasScope) {
      hasNew.value = false;
      return;
    }
    _lastScope = scope;

    try {
      final snapshot = await _queryForScope(db, scope).limit(100).get();
      await _refreshFromDocs(snapshot.docs);
    } catch (_) {
      hasNew.value = false;
    }
  }

  /// Marks all current published polls as seen and clears the badge.
  Future<void> markAllSeen() async {
    final db = FirestoreDataService.instance;
    if (db == null) {
      hasNew.value = false;
      return;
    }

    final scope = _lastScope ?? await _communeScope();
    if (scope == null || !scope.hasScope) {
      hasNew.value = false;
      return;
    }

    try {
      final ids = await _visiblePollIdsForScope(db, scope);
      await BrowserStorageService.instance.writeJsonList(_seenKey, ids);
      hasNew.value = false;
    } catch (_) {
      hasNew.value = false;
    }
  }
}

class _CommuneScope {
  const _CommuneScope({
    required this.communeId,
    required this.communeName,
  });

  final String communeId;
  final String communeName;

  bool get hasScope => communeId.isNotEmpty || communeName.isNotEmpty;

  String get key =>
      communeId.isNotEmpty ? 'id:$communeId' : 'name:$communeName';
}
