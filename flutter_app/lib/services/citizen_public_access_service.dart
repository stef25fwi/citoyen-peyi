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

  Map<String, dynamic> toJson() => {
        'accessCode': accessCode,
        'communeId': communeId,
        'communeName': communeName,
        'openPolls': openPolls.map((item) => item.toJson()).toList(),
        'votedPollIds': votedPollIds.toList(),
      };

  static CitizenPublicAccessSession? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    final accessCode = raw['accessCode'] as String? ?? '';
    final communeId = raw['communeId'] as String? ?? '';
    final communeName = raw['communeName'] as String? ?? '';
    if (accessCode.trim().isEmpty || communeId.trim().isEmpty) {
      return null;
    }

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

  static CitizenPollAccessRecord fromJson(Map<String, dynamic> json,
      {String? id}) {
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

  CitizenPublicAccessSession? get currentSession => _currentSession;

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
    } catch (_) {
      _currentSession = null;
    }
  }

  Future<void> saveSession(CitizenPublicAccessSession session) async {
    _preferences ??= await SharedPreferences.getInstance();
    _currentSession = session;
    await _preferences?.setString(_storageKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    _preferences ??= await SharedPreferences.getInstance();
    _currentSession = null;
    await _preferences?.remove(_storageKey);
  }

  Future<CitizenPublicAccessSession?> openAccess(String rawCode) async {
    final normalizedCode = resolveVoteAccessCode(rawCode) ?? rawCode.trim();
    final session = _currentSession;
    if (session != null && session.accessCode.trim() == normalizedCode.trim()) {
      return session;
    }
    return null;
  }

  /// Construit une session citoyen directement depuis le résultat de validation
  /// backend, utilisé comme fallback quand la lecture Firestore côté client est
  /// bloquée par les règles de sécurité (ex: citizen_access_codes en prod).
  CitizenPublicAccessSession sessionFromValidation({
    required String rawCode,
    required VoteAccessValidationResult validation,
  }) {
    final code = resolveVoteAccessCode(rawCode) ?? rawCode.trim();
    final openPolls = validation.eligiblePolls
        .where((p) => p.status == 'open' && !p.hasVoted)
        .map(
          (p) => PollModel(
            id: p.pollId,
            projectTitle: p.title,
            description: p.description,
            question: p.question,
            options: p.options
                .asMap()
                .entries
                .map((e) => PollOptionModel(
                    id: e.value.id, label: e.value.label, votes: 0))
                .toList(),
            photoUrls: p.photoUrls,
            openDate: '',
            closeDate: '',
            status: 'open',
            totalVoters: 0,
            totalVoted: 0,
          ),
        )
        .toList();
    final votedPollIds = validation.eligiblePolls
        .where((p) => p.hasVoted)
        .map((p) => p.pollId)
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

  Future<bool> hasVoted(
      {required String accessCode, required String pollId}) async {
    return false;
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

  Future<void> markVoted(
      {required String accessCode, required String pollId}) async {
    return;
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
            .map((doc) =>
                CitizenPollAccessRecord.fromJson(doc.data(), id: doc.id))
            .toList();
      } catch (_) {
        records = <CitizenPollAccessRecord>[];
      }
    } else {
      records = <CitizenPollAccessRecord>[];
    }

    return records.where((item) {
      if (pollId?.isNotEmpty == true && item.pollId != pollId) {
        return false;
      }
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
    final date = DateTime.tryParse('$value');
    return date;
  }
}
