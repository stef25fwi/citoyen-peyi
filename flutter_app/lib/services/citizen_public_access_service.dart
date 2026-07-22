import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/poll_models.dart';
import 'auth_session_store.dart';
import 'firestore_data_service.dart';
import 'vote_access_service.dart';

String _readStoredDateString(Object? value) {
  if (value == null) return '';
  if (value is Timestamp) return value.toDate().toIso8601String();
  return value.toString();
}

class CitizenPublicAccessSession {
  const CitizenPublicAccessSession({
    required this.accessCode,
    required this.communeId,
    required this.communeName,
    required this.openPolls,
    required this.votedPollIds,
  });

  final String accessCode;
  final String communeId;
  final String communeName;
  final List<PollModel> openPolls;
  final Set<String> votedPollIds;

  bool hasVoted(String pollId) => votedPollIds.contains(pollId);

  CitizenPublicAccessSession copyWith({
    List<PollModel>? openPolls,
    Set<String>? votedPollIds,
  }) {
    return CitizenPublicAccessSession(
      accessCode: accessCode,
      communeId: communeId,
      communeName: communeName,
      openPolls: openPolls ?? this.openPolls,
      votedPollIds: votedPollIds ?? this.votedPollIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessCode': accessCode,
        'communeId': communeId,
        'communeName': communeName,
        'openPolls': openPolls.map((item) => item.toJson()).toList(),
        'votedPollIds': votedPollIds.toList(),
      };

  static CitizenPublicAccessSession? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;

    final accessCode = raw['accessCode'] as String? ?? '';
    final communeId = raw['communeId'] as String? ?? '';
    final communeName = raw['communeName'] as String? ?? '';
    if (accessCode.trim().isEmpty || communeId.trim().isEmpty) return null;

    final rawPolls = (raw['openPolls'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PollModel.fromJson)
        .toList(growable: false);
    final votedPollIds =
        (raw['votedPollIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet();

    return CitizenPublicAccessSession(
      accessCode: accessCode.trim(),
      communeId: communeId.trim(),
      communeName: communeName.trim(),
      openPolls: rawPolls,
      votedPollIds: votedPollIds,
    );
  }
}

class CitizenPollAccessRecord {
  const CitizenPollAccessRecord({
    required this.id,
    required this.accessCodeHash,
    required this.pollId,
    required this.votedAt,
    this.communeId = '',
  });

  final String id;
  final String accessCodeHash;
  final String pollId;
  final String votedAt;
  final String communeId;

  static CitizenPollAccessRecord fromJson(
    Map<String, dynamic> json, {
    String? id,
  }) {
    return CitizenPollAccessRecord(
      id: id ?? json['id'] as String? ?? '',
      accessCodeHash: json['accessCodeHash'] as String? ?? '',
      pollId: json['pollId'] as String? ?? '',
      votedAt: _readStoredDateString(json['votedAt']),
      communeId: json['communeId'] as String? ?? '',
    );
  }
}

class CitizenPublicAccessService {
  CitizenPublicAccessService._();

  static final CitizenPublicAccessService instance =
      CitizenPublicAccessService._();
  static const _pollAccessCollection = 'citizen_poll_access';
  static const _storageKey = 'citizen_public_access_session_v1';

  SharedPreferences? _preferences;
  CitizenPublicAccessSession? _currentSession;
  DateTime? _firstConnectionAt;
  DateTime? _lastConnectionAt;

  static const _firstSeenPrefix = 'citizen_first_seen_';
  static const _lastSeenPrefix = 'citizen_last_seen_';
  static const _notificationCategoryKey = 'citizen_notification_category_v1';

  CitizenPublicAccessSession? get currentSession => _currentSession;
  DateTime? get firstConnectionAt => _firstConnectionAt;
  DateTime? get lastConnectionAt => _lastConnectionAt;

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    final raw = _preferences?.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _currentSession = null;
      return;
    }

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _currentSession = CitizenPublicAccessSession.fromJson(data);
      if (_currentSession != null) {
        await _recordConnection(_currentSession!.accessCode);
      }
    } catch (_) {
      _currentSession = null;
    }
  }

  Future<void> saveSession(CitizenPublicAccessSession session) async {
    _preferences ??= await SharedPreferences.getInstance();
    _currentSession = session;
    await _preferences?.setString(_storageKey, jsonEncode(session.toJson()));
    await _recordConnection(session.accessCode);
  }

  Future<void> clearSession() async {
    _preferences ??= await SharedPreferences.getInstance();
    _currentSession = null;
    await _preferences?.remove(_storageKey);
  }

  Future<void> _recordConnection(String accessCode) async {
    final code = accessCode.trim();
    if (code.isEmpty) return;
    _preferences ??= await SharedPreferences.getInstance();

    final firstKey = '$_firstSeenPrefix$code';
    final lastKey = '$_lastSeenPrefix$code';
    final now = DateTime.now();

    final existingFirst = _preferences?.getString(firstKey);
    if (existingFirst == null || existingFirst.isEmpty) {
      await _preferences?.setString(firstKey, now.toIso8601String());
      _firstConnectionAt = now;
    } else {
      _firstConnectionAt = DateTime.tryParse(existingFirst) ?? now;
    }

    await _preferences?.setString(lastKey, now.toIso8601String());
    _lastConnectionAt = now;
  }

  Future<CitizenPublicAccessSession?> openAccess(String rawCode) async {
    final normalizedCode = resolveVoteAccessCode(rawCode) ?? rawCode.trim();
    final session = _currentSession;
    if (session != null && session.accessCode.trim() == normalizedCode.trim()) {
      return session;
    }
    return null;
  }

  CitizenPublicAccessSession sessionFromValidation({
    required String rawCode,
    required VoteAccessValidationResult validation,
  }) {
    final code = resolveVoteAccessCode(rawCode) ?? rawCode.trim();
    final openPolls = validation.eligiblePolls
        .where(
          (poll) =>
              (poll.status == 'open' || poll.status == 'active') &&
              !poll.hasVoted,
        )
        .map(
          (poll) => PollModel(
            id: poll.pollId,
            projectTitle: poll.title,
            description: poll.description,
            question: poll.question,
            options: poll.options
                .map(
                  (option) => PollOptionModel(
                    id: option.id,
                    label: option.label,
                    votes: 0,
                  ),
                )
                .toList(growable: false),
            photoUrls: poll.photoUrls,
            openDate: '',
            closeDate: '',
            status: 'active',
            totalVoters: 0,
            totalVoted: 0,
          ),
        )
        .toList(growable: false);
    final votedPollIds = validation.eligiblePolls
        .where((poll) => poll.hasVoted)
        .map((poll) => poll.pollId)
        .toSet();
    final session = CitizenPublicAccessSession(
      accessCode: code,
      communeId: validation.communeId,
      communeName: validation.communeName,
      openPolls: openPolls,
      votedPollIds: votedPollIds,
    );
    _currentSession = session;
    return session;
  }

  Future<bool> hasVoted({
    required String accessCode,
    required String pollId,
  }) async {
    final session = _currentSession;
    if (session == null) return false;
    final normalized = resolveVoteAccessCode(accessCode) ?? accessCode.trim();
    if (session.accessCode.trim() != normalized.trim()) return false;
    return session.hasVoted(pollId);
  }

  Future<void> markVoted({
    required String accessCode,
    required String pollId,
  }) async {
    final session = _currentSession;
    if (session == null || pollId.trim().isEmpty) return;
    final normalized = resolveVoteAccessCode(accessCode) ?? accessCode.trim();
    if (session.accessCode.trim() != normalized.trim()) return;

    final nextVoted = <String>{...session.votedPollIds, pollId.trim()};
    final nextPolls = session.openPolls
        .where((poll) => poll.id.trim() != pollId.trim())
        .toList(growable: false);
    await saveSession(
      session.copyWith(openPolls: nextPolls, votedPollIds: nextVoted),
    );
  }

  Future<List<DateTime>> loadVoteDatesForCurrentCommune() async {
    final session = AuthSessionStore.instance.currentSession;
    final communeId = session?.commune?.code ?? session?.commune?.name ?? '';
    final db = FirestoreDataService.instance;

    if (db != null) {
      try {
        Query<Map<String, dynamic>> query =
            db.collection(_pollAccessCollection);
        if (communeId.isNotEmpty) {
          query = query.where('communeId', isEqualTo: communeId);
        }
        final snapshot =
            await query.orderBy('votedAt', descending: true).limit(250).get();
        return snapshot.docs
            .map((doc) => _asDateTime(doc.data()['votedAt']))
            .whereType<DateTime>()
            .toList();
      } catch (_) {
        return const <DateTime>[];
      }
    }

    return const <DateTime>[];
  }

  Future<List<CitizenPollAccessRecord>> loadVoteRecords({
    String? pollId,
    String? communeId,
    int limit = 250,
  }) async {
    final db = FirestoreDataService.instance;
    List<CitizenPollAccessRecord> records;

    if (db != null) {
      try {
        Query<Map<String, dynamic>> query =
            db.collection(_pollAccessCollection);
        if (pollId?.isNotEmpty == true) {
          query = query.where('pollId', isEqualTo: pollId);
        }
        if (communeId?.isNotEmpty == true) {
          query = query.where('communeId', isEqualTo: communeId);
        }
        final snapshot =
            await query.orderBy('votedAt', descending: true).limit(limit).get();
        records = snapshot.docs
            .map(
              (doc) => CitizenPollAccessRecord.fromJson(
                doc.data(),
                id: doc.id,
              ),
            )
            .toList();
      } catch (_) {
        records = <CitizenPollAccessRecord>[];
      }
    } else {
      records = <CitizenPollAccessRecord>[];
    }

    return records.where((item) {
      if (pollId?.isNotEmpty == true && item.pollId != pollId) return false;
      if (communeId?.isNotEmpty == true &&
          item.communeId.isNotEmpty &&
          item.communeId != communeId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((left, right) => right.votedAt.compareTo(left.votedAt));
  }

  DateTime? _asDateTime(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse('$value');
  }

  String get _scopedNotificationCategoryKey {
    final session = _currentSession;
    final scope = session == null
        ? 'anonymous'
        : '${session.communeId}_${session.accessCode}';
    return '${_notificationCategoryKey}_$scope';
  }

  Future<String?> loadNotificationCategory() async {
    _preferences ??= await SharedPreferences.getInstance();
    final value = _preferences?.getString(_scopedNotificationCategoryKey);
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> saveNotificationCategory(String? category) async {
    _preferences ??= await SharedPreferences.getInstance();
    final key = _scopedNotificationCategoryKey;
    if (category == null || category.isEmpty) {
      await _preferences?.remove(key);
    } else {
      await _preferences?.setString(key, category);
    }
  }
}
