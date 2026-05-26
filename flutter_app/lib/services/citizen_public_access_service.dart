import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../models/poll_models.dart';
import 'auth_session_store.dart';
import 'browser_storage_service.dart';
import 'citizen_access_code_service.dart';
import 'firestore_data_service.dart';
import 'poll_service.dart';
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

  static CitizenPollAccessRecord fromJson(Map<String, dynamic> json, {String? id}) {
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

  static final CitizenPublicAccessService instance = CitizenPublicAccessService._();
  static const _pollAccessCollection = 'citizen_poll_access';
  static const _localPollAccessKey = 'citizen_poll_access_v1';

  Future<CitizenPublicAccessSession?> openAccess(String rawCode) async {
    final normalizedCode = resolveVoteAccessCode(rawCode) ?? rawCode.trim();
    final access = await CitizenAccessCodeService.instance.findActiveAccessCode(normalizedCode);
    if (access == null) return null;

    final polls = await PollService.instance.loadPolls();
    final openPolls = polls
      .where((poll) => _isOpenPollForPublic(poll) && _matchesCitizenCommune(poll, access.communeId, access.communeName))
      .toList();
    final votedPollIds = await _loadVotedPollIds(access.accessCode);

    return CitizenPublicAccessSession(
      accessCode: access.accessCode,
      communeId: access.communeId,
      communeName: access.communeName,
      openPolls: openPolls,
      votedPollIds: votedPollIds,
    );
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
                .map((e) => PollOptionModel(id: e.value.id, label: e.value.label, votes: 0))
                .toList(),
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
    return CitizenPublicAccessSession(
      accessCode: code,
      communeId: validation.communeId,
      communeName: validation.communeName,
      openPolls: openPolls,
      votedPollIds: votedPollIds,
    );
  }

  Future<bool> hasVoted({required String accessCode, required String pollId}) async {
    final votedPollIds = await _loadVotedPollIds(accessCode);
    return votedPollIds.contains(pollId);
  }

  Future<List<DateTime>> loadVoteDatesForCurrentCommune() async {
    final session = AuthSessionStore.instance.currentSession;
    final communeId = session?.commune?.code ?? session?.commune?.name ?? '';
    final db = FirestoreDataService.instance;

    if (db != null) {
      try {
        Query<Map<String, dynamic>> query = db.collection(_pollAccessCollection);
        if (communeId.isNotEmpty) {
          query = query.where('communeId', isEqualTo: communeId);
        }
        final snapshot = await query.orderBy('votedAt', descending: true).limit(250).get();
        return snapshot.docs
            .map((doc) => _asDateTime(doc.data()['votedAt']))
            .whereType<DateTime>()
            .toList();
      } catch (_) {
        return _loadLocalVoteDates();
      }
    }

    return _loadLocalVoteDates();
  }

  Future<void> markVoted({required String accessCode, required String pollId}) async {
    final docId = _accessDocId(accessCode: accessCode, pollId: pollId);
    final now = DateTime.now().toIso8601String();
    final access = await CitizenAccessCodeService.instance.findActiveAccessCode(accessCode);
    final payload = {
      'id': docId,
      'accessCodeHash': _hashAccessCode(accessCode),
      'pollId': pollId,
      'votedAt': now,
      'communeId': access?.communeId ?? '',
    };

    final db = FirestoreDataService.instance;
    if (db != null) {
      try {
        await db.collection(_pollAccessCollection).doc(docId).set({
          ...payload,
          'votedAt': Timestamp.fromDate(DateTime.parse(now)),
        }, SetOptions(merge: true));
      } catch (_) {
        await _markVotedLocal(payload);
      }
    } else {
      await _markVotedLocal(payload);
    }

    await CitizenAccessCodeService.instance.markAccessCodeUsedForPublicVote(accessCode);
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
        Query<Map<String, dynamic>> query = db.collection(_pollAccessCollection);
        if (pollId?.isNotEmpty == true) {
          query = query.where('pollId', isEqualTo: pollId);
        }
        if (communeId?.isNotEmpty == true) {
          query = query.where('communeId', isEqualTo: communeId);
        }
        final snapshot = await query.orderBy('votedAt', descending: true).limit(limit).get();
        records = snapshot.docs.map((doc) => CitizenPollAccessRecord.fromJson(doc.data(), id: doc.id)).toList();
      } catch (_) {
        records = await _loadLocalVoteRecords();
      }
    } else {
      records = await _loadLocalVoteRecords();
    }

    return records.where((item) {
      if (pollId?.isNotEmpty == true && item.pollId != pollId) {
        return false;
      }
      if (communeId?.isNotEmpty == true && item.communeId.isNotEmpty && item.communeId != communeId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((left, right) => right.votedAt.compareTo(left.votedAt));
  }

  bool _isOpenPollForPublic(PollModel poll) {
    final today = DateTime.now().toIso8601String().split('T').first;
    final opened = poll.openDate.isEmpty || poll.openDate.compareTo(today) <= 0;
    final notClosed = poll.closeDate.isEmpty || poll.closeDate.compareTo(today) >= 0;
    return poll.status == 'active' && opened && notClosed;
  }

  bool _matchesCitizenCommune(PollModel poll, String communeId, String communeName) {
    if (poll.communeId.isEmpty && poll.communeName.isEmpty) {
      return true;
    }

    if (poll.communeId.isNotEmpty && communeId.isNotEmpty) {
      return poll.communeId == communeId;
    }

    if (poll.communeName.isNotEmpty && communeName.isNotEmpty) {
      return poll.communeName.toLowerCase() == communeName.toLowerCase();
    }

    return false;
  }

  Future<Set<String>> _loadVotedPollIds(String accessCode) async {
    final hash = _hashAccessCode(accessCode);
    final db = FirestoreDataService.instance;
    if (db != null) {
      try {
        final snapshot = await db.collection(_pollAccessCollection).where('accessCodeHash', isEqualTo: hash).get();
        return snapshot.docs.map((doc) => doc.data()['pollId'] as String? ?? '').where((item) => item.isNotEmpty).toSet();
      } catch (_) {
        return _loadLocalVotedPollIds(hash);
      }
    }

    return _loadLocalVotedPollIds(hash);
  }

  Future<Set<String>> _loadLocalVotedPollIds(String accessCodeHash) async {
    final records = await BrowserStorageService.instance.readJsonList(_localPollAccessKey);
    return records
        .where((item) => item['accessCodeHash'] == accessCodeHash)
        .map((item) => item['pollId'] as String? ?? '')
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Future<void> _markVotedLocal(Map<String, dynamic> payload) async {
    final records = await BrowserStorageService.instance.readJsonList(_localPollAccessKey);
    final exists = records.any((item) => item['id'] == payload['id']);
    if (exists) return;
    await BrowserStorageService.instance.writeJsonList(_localPollAccessKey, [payload, ...records]);
  }

  Future<List<CitizenPollAccessRecord>> _loadLocalVoteRecords() async {
    final records = await BrowserStorageService.instance.readJsonList(_localPollAccessKey);
    return records.map((item) => CitizenPollAccessRecord.fromJson(item)).toList();
  }

  Future<List<DateTime>> _loadLocalVoteDates() async {
    final records = await BrowserStorageService.instance.readJsonList(_localPollAccessKey);
    return records
        .map((item) => _asDateTime(item['votedAt']))
        .whereType<DateTime>()
        .toList();
  }

  DateTime? _asDateTime(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    final date = DateTime.tryParse('$value');
    return date;
  }

  String _accessDocId({required String accessCode, required String pollId}) {
    return sha256.convert(utf8.encode('${accessCode.trim().toUpperCase()}::$pollId')).toString();
  }

  String _hashAccessCode(String accessCode) {
    return sha256.convert(utf8.encode(accessCode.trim().toUpperCase())).toString();
  }

}
