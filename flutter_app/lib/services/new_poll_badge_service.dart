import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth_session_store.dart';
import 'browser_storage_service.dart';
import 'citizen_commune_store.dart';
import 'firestore_data_service.dart';

enum CitizenNotificationType { consultation, news, result }

class CitizenNotificationItem {
  const CitizenNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.route,
  });

  final String id;
  final CitizenNotificationType type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final String route;

  String get storageId => '${type.name}:$id';
}

/// Centre de notifications du parcours citoyen.
///
/// Le nom historique de la classe est conservé pour ne pas casser les appels
/// existants. Le service suit désormais les consultations, les actualités et
/// les résultats publiés pour la commune du citoyen.
class NewPollBadgeService {
  NewPollBadgeService._();

  static final NewPollBadgeService instance = NewPollBadgeService._();

  static const _seenKey = 'seen_citizen_notifications_v2';
  static const _pollCollection = 'public_polls';
  static const _newsCollection = 'public_news';

  final ValueNotifier<bool> hasNew = ValueNotifier<bool>(false);
  final ValueNotifier<int> newCount = ValueNotifier<int>(0);
  final ValueNotifier<List<CitizenNotificationItem>> notifications =
      ValueNotifier<List<CitizenNotificationItem>>(const []);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pollSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _newsSubscription;
  String? _lastScopeKey;
  _CommuneScope? _lastScope;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _pollDocs = const [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _newsDocs = const [];

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

  Future<void> _writeSeenIds(Set<String> ids) async {
    await BrowserStorageService.instance.writeJsonList(
      _seenKey,
      ids.map((id) => <String, dynamic>{'id': id}).toList(),
    );
  }

  DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.length == 10 ? '${raw}T00:00:00' : raw);
  }

  bool _matchesScope(Map<String, dynamic> data, _CommuneScope scope) {
    final communeId = (data['communeId'] as String? ?? '').trim();
    final communeName = (data['communeName'] as String? ?? '').trim();

    if (communeId.isEmpty && communeName.isEmpty) return true;
    if (scope.communeId.isNotEmpty && communeId == scope.communeId) return true;
    return scope.communeName.isNotEmpty &&
        communeName.toLowerCase() == scope.communeName.toLowerCase();
  }

  bool _isOpenPoll(Map<String, dynamic> data) {
    final status = (data['status'] as String? ?? '').trim().toLowerCase();
    final now = DateTime.now();
    final scheduledPublishDate = _readDate(
      data['scheduledPublishDate'] ?? data['publishDate'],
    );
    final scheduledIsDue = status == 'scheduled' &&
        scheduledPublishDate != null &&
        !scheduledPublishDate.isAfter(now);

    if (!['active', 'open'].contains(status) && !scheduledIsDue) return false;

    final opensAt = _readDate(data['opensAt'] ?? data['openDate']);
    final closesAt = _readDate(data['closesAt'] ?? data['closeDate']);
    if (opensAt != null && opensAt.isAfter(now)) return false;
    if (closesAt != null && closesAt.isBefore(now)) return false;
    return true;
  }

  bool _hasPublishedResults(Map<String, dynamic> data) {
    final status = (data['status'] as String? ?? '').trim().toLowerCase();
    final explicitlyPublished = data['resultsPublished'] == true ||
        data['resultPublished'] == true ||
        _readDate(data['resultsPublishedAt'] ?? data['resultPublishedAt']) != null;
    return explicitlyPublished || ['closed', 'archived'].contains(status);
  }

  String _pollTitle(Map<String, dynamic> data) =>
      (data['title'] as String? ?? data['name'] as String? ?? 'Consultation')
          .trim();

  DateTime _notificationDate(Map<String, dynamic> data) {
    return _readDate(
          data['resultsPublishedAt'] ??
              data['resultPublishedAt'] ??
              data['publishedAt'] ??
              data['updatedAt'] ??
              data['createdAt'] ??
              data['openDate'],
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<CitizenNotificationItem> _buildNotifications(_CommuneScope scope) {
    final items = <CitizenNotificationItem>[];

    for (final doc in _pollDocs) {
      final data = doc.data();
      if (!_matchesScope(data, scope)) continue;
      final title = _pollTitle(data);
      final communeName = (data['communeName'] as String? ?? '').trim();
      if (_isOpenPoll(data)) {
        items.add(
          CitizenNotificationItem(
            id: doc.id,
            type: CitizenNotificationType.consultation,
            title: title.isEmpty ? 'Nouvelle consultation' : title,
            subtitle: communeName.isEmpty
                ? 'Une nouvelle consultation est ouverte.'
                : 'Nouvelle consultation · $communeName',
            createdAt: _notificationDate(data),
            route: '/citizen/consultations',
          ),
        );
      } else if (_hasPublishedResults(data)) {
        items.add(
          CitizenNotificationItem(
            id: doc.id,
            type: CitizenNotificationType.result,
            title: title.isEmpty ? 'Résultats publiés' : title,
            subtitle: communeName.isEmpty
                ? 'Les résultats de cette consultation sont disponibles.'
                : 'Résultats publiés · $communeName',
            createdAt: _notificationDate(data),
            route: '/results',
          ),
        );
      }
    }

    for (final doc in _newsDocs) {
      final data = doc.data();
      if (!_matchesScope(data, scope)) continue;
      final title =
          (data['title'] as String? ?? 'Nouvelle actualité').trim();
      final communeName = (data['communeName'] as String? ?? '').trim();
      items.add(
        CitizenNotificationItem(
          id: doc.id,
          type: CitizenNotificationType.news,
          title: title.isEmpty ? 'Nouvelle actualité' : title,
          subtitle: communeName.isEmpty
              ? 'Une nouvelle actualité vient d’être publiée.'
              : 'Nouvelle actualité · $communeName',
          createdAt: _notificationDate(data),
          route: '/news',
        ),
      );
    }

    items.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return items.take(100).toList(growable: false);
  }

  Future<void> _refresh() async {
    final scope = _lastScope;
    if (scope == null || !scope.hasScope) {
      notifications.value = const [];
      hasNew.value = false;
      newCount.value = 0;
      return;
    }

    final items = _buildNotifications(scope);
    final seen = await _seenIds();
    final unseenCount = items.where((item) => !seen.contains(item.storageId)).length;
    notifications.value = items;
    newCount.value = unseenCount;
    hasNew.value = unseenCount > 0;
  }

  Future<void> _reset() async {
    await _pollSubscription?.cancel();
    await _newsSubscription?.cancel();
    _pollSubscription = null;
    _newsSubscription = null;
    _pollDocs = const [];
    _newsDocs = const [];
    _lastScope = null;
    _lastScopeKey = null;
    notifications.value = const [];
    hasNew.value = false;
    newCount.value = 0;
  }

  Future<void> startListening() async {
    final db = FirestoreDataService.instance;
    if (db == null) {
      await _reset();
      return;
    }

    final scope = await _communeScope();
    if (scope == null || !scope.hasScope) {
      await _reset();
      return;
    }

    _lastScope = scope;
    if (_pollSubscription != null &&
        _newsSubscription != null &&
        _lastScopeKey == scope.key) {
      await check();
      return;
    }

    await _pollSubscription?.cancel();
    await _newsSubscription?.cancel();
    _lastScopeKey = scope.key;

    _pollSubscription = db.collection(_pollCollection).limit(100).snapshots().listen(
      (snapshot) {
        _pollDocs = snapshot.docs;
        unawaited(_refresh());
      },
      onError: (_) => unawaited(check()),
    );
    _newsSubscription = db.collection(_newsCollection).limit(100).snapshots().listen(
      (snapshot) {
        _newsDocs = snapshot.docs;
        unawaited(_refresh());
      },
      onError: (_) => unawaited(check()),
    );

    await check();
  }

  Future<void> check() async {
    final db = FirestoreDataService.instance;
    final scope = await _communeScope();
    if (db == null || scope == null || !scope.hasScope) {
      await _reset();
      return;
    }

    _lastScope = scope;
    try {
      final snapshots = await Future.wait([
        db.collection(_pollCollection).limit(100).get(),
        db.collection(_newsCollection).limit(100).get(),
      ]);
      _pollDocs = snapshots[0].docs;
      _newsDocs = snapshots[1].docs;
      await _refresh();
    } catch (_) {
      notifications.value = const [];
      hasNew.value = false;
      newCount.value = 0;
    }
  }

  Future<void> markSeen(CitizenNotificationItem item) async {
    final seen = await _seenIds();
    seen.add(item.storageId);
    await _writeSeenIds(seen);
    await _refresh();
  }

  Future<void> markAllSeen() async {
    final ids = notifications.value.map((item) => item.storageId).toSet();
    await _writeSeenIds(ids);
    hasNew.value = false;
    newCount.value = 0;
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
