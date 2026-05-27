import 'package:flutter/foundation.dart';

import 'auth_session_store.dart';
import 'browser_storage_service.dart';
import 'firestore_data_service.dart';

/// Tracks open polls not yet seen by the user.
/// Call [check] on app boot / nav-bar build.
/// Call [markAllSeen] when the user lands on the vote/access page.
class NewPollBadgeService {
  NewPollBadgeService._();

  static final NewPollBadgeService instance = NewPollBadgeService._();

  static const _seenKey = 'seen_poll_ids_v1';
  static const _pollCollection = 'polls';

  final ValueNotifier<bool> hasNew = ValueNotifier<bool>(false);

  String? _lastCommuneId;

  // ── helpers ──────────────────────────────────────────────────────────────

  String? _communeId() {
    final session = AuthSessionStore.instance.currentSession;
    return session?.commune?.code ?? session?.commune?.name;
  }

  Future<Set<String>> _seenIds() async {
    final raw = await BrowserStorageService.instance.readJsonList(_seenKey);
    return raw.map((m) => m['id'] as String?).whereType<String>().toSet();
  }

  // ── public API ───────────────────────────────────────────────────────────

  /// Queries Firestore for open polls of the user's commune and sets [hasNew].
  Future<void> check() async {
    final db = FirestoreDataService.instance;
    if (db == null) return;

    final communeId = _communeId();
    _lastCommuneId = communeId;

    try {
      var query =
          db.collection(_pollCollection).where('status', isEqualTo: 'open');
      if (communeId != null && communeId.isNotEmpty) {
        query = query.where('communeId', isEqualTo: communeId);
      }

      final snapshot = await query.get();
      final liveIds = snapshot.docs.map((d) => d.id).toSet();
      final seen = await _seenIds();

      hasNew.value = liveIds.difference(seen).isNotEmpty;
    } catch (_) {
      // Silently fail — no badge on error.
    }
  }

  /// Marks all current open polls as seen and clears the badge.
  Future<void> markAllSeen() async {
    final db = FirestoreDataService.instance;
    if (db == null) {
      hasNew.value = false;
      return;
    }

    try {
      final communeId = _lastCommuneId ?? _communeId();
      var query =
          db.collection(_pollCollection).where('status', isEqualTo: 'open');
      if (communeId != null && communeId.isNotEmpty) {
        query = query.where('communeId', isEqualTo: communeId);
      }

      final snapshot = await query.get();
      final ids =
          snapshot.docs.map((d) => <String, dynamic>{'id': d.id}).toList();
      await BrowserStorageService.instance.writeJsonList(_seenKey, ids);
      hasNew.value = false;
    } catch (_) {
      hasNew.value = false;
    }
  }
}
