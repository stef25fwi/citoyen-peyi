import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/poll_models.dart';
import 'browser_storage_service.dart';
import 'firestore_data_service.dart';

class VoteAccessException implements Exception {
  const VoteAccessException(this.message, {this.errorCode = 'UNKNOWN'});

  final String message;
  final String errorCode;

  @override
  String toString() => message;
}

class EligiblePollOption {
  const EligiblePollOption({required this.id, required this.label});

  final String id;
  final String label;

  static EligiblePollOption fromJson(Map<String, dynamic> json) {
    return EligiblePollOption(
      id: (json['id'] as String? ?? '').trim(),
      label: (json['label'] as String? ?? '').trim(),
    );
  }
}

class EligiblePollModel {
  const EligiblePollModel({
    required this.pollId,
    required this.title,
    required this.status,
    required this.hasVoted,
    this.description = '',
    this.question = '',
    this.options = const [],
  });

  final String pollId;
  final String title;
  final String status;
  final bool hasVoted;
  final String description;
  final String question;
  final List<EligiblePollOption> options;

  static EligiblePollModel fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return EligiblePollModel(
      pollId: json['pollId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['projectTitle'] as String? ?? 'Consultation',
      status: json['status'] as String? ?? 'open',
      hasVoted: json['hasVoted'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(EligiblePollOption.fromJson)
          .where((option) => option.id.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class VoteAccessValidationResult {
  const VoteAccessValidationResult({
    required this.accessToken,
    required this.accessCodeId,
    required this.communeId,
    required this.communeName,
    required this.eligiblePolls,
  });

  final String accessToken;
  final String accessCodeId;
  final String communeId;
  final String communeName;
  final List<EligiblePollModel> eligiblePolls;
}

class VoteSubmitResult {
  const VoteSubmitResult({required this.receiptId, required this.message});

  final String receiptId;
  final String message;
}

class VoteAccessService {
  VoteAccessService._();

  // Compatibilite temporaire uniquement. Le flux principal citoyen passe par
  // citizen_access_codes via CitizenAccessCodeService.

  static const _registrationStorageKey = 'registration_codes_v1';
  static const _registrationCollection = 'registrationCodes';
  static final VoteAccessService instance = VoteAccessService._();
  static final Random _random = Random();

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<VoteAccessValidationResult> validateCode(String rawCode, {String? pollId}) async {
    final code = parseCodeOrQrUrl(rawCode);
    if (code == null || code.isEmpty) {
      throw const VoteAccessException('Code citoyen requis.', errorCode: 'INVALID_CODE');
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/vote-access/validate'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          if (pollId?.trim().isNotEmpty == true) 'pollId': pollId!.trim(),
        }),
      ).timeout(const Duration(seconds: 12));
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300 || payload['ok'] != true) {
        throw VoteAccessException(
          payload['message'] as String? ?? 'Code inconnu, expire ou desactive.',
          errorCode: payload['errorCode'] as String? ?? 'INVALID_CODE',
        );
      }
      final eligiblePolls = (payload['eligiblePolls'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EligiblePollModel.fromJson)
          .where((poll) => poll.pollId.isNotEmpty)
          .toList();

      return VoteAccessValidationResult(
        accessToken: payload['accessToken'] as String? ?? '',
        accessCodeId: payload['accessCodeId'] as String? ?? '',
        communeId: payload['communeId'] as String? ?? '',
        communeName: payload['communeName'] as String? ?? '',
        eligiblePolls: eligiblePolls,
      );
    } on VoteAccessException {
      rethrow;
    } catch (_) {
      throw const VoteAccessException('Validation securisee indisponible. Reessayez plus tard.', errorCode: 'NETWORK_ERROR');
    }
  }

  Future<VoteSubmitResult> submitVote({
    required String accessToken,
    required String pollId,
    required String optionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/vote-access/submit'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': accessToken,
          'pollId': pollId,
          'optionId': optionId,
          'source': 'web',
        }),
      ).timeout(const Duration(seconds: 12));
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300 || payload['ok'] != true) {
        throw VoteAccessException(
          payload['message'] as String? ?? 'Enregistrement du vote impossible.',
          errorCode: payload['errorCode'] as String? ?? 'SUBMIT_FAILED',
        );
      }
      return VoteSubmitResult(
        receiptId: payload['receiptId'] as String? ?? '',
        message: payload['message'] as String? ?? 'Votre vote est enregistre anonymement.',
      );
    } on VoteAccessException {
      rethrow;
    } catch (_) {
      throw const VoteAccessException('Reseau indisponible. Votre vote n’a pas ete enregistre.', errorCode: 'NETWORK_ERROR');
    }
  }

  String? parseCodeOrQrUrl(String rawValue) => resolveVoteAccessCode(rawValue);

  Future<void> _writeLocal(List<VoteAccessRecordModel> records) {
    return BrowserStorageService.instance.writeJsonList(
      _registrationStorageKey,
      records.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> _saveRecord(VoteAccessRecordModel record) async {
    final records = await _loadAll();
    final nextRecords = records.any((item) => item.id == record.id)
        ? records.map((item) => item.id == record.id ? record : item).toList()
        : [record, ...records];
    await _writeLocal(nextRecords);

    final db = FirestoreDataService.instance;
    if (db != null) {
      await db.collection(_registrationCollection).doc(record.id).set(
        record.toJson(),
        SetOptions(merge: true),
      );
    }
  }

  Future<List<VoteAccessRecordModel>> _loadAll() async {
    final db = FirestoreDataService.instance;
    if (db == null) {
      final records = await BrowserStorageService.instance.readJsonList(_registrationStorageKey);
      return records
          .whereType<Map<String, dynamic>>()
          .map(VoteAccessRecordModel.fromJson)
          .whereType<VoteAccessRecordModel>()
          .toList();
    }

    try {
      final snapshot = await db.collection(_registrationCollection).get();
      if (snapshot.docs.isEmpty) {
        final records = await BrowserStorageService.instance.readJsonList(_registrationStorageKey);
        return records
            .whereType<Map<String, dynamic>>()
            .map(VoteAccessRecordModel.fromJson)
            .whereType<VoteAccessRecordModel>()
            .toList();
      }

      final records = snapshot.docs
          .map((item) => VoteAccessRecordModel.fromJson(item.data()))
          .whereType<VoteAccessRecordModel>()
          .toList();
      await _writeLocal(records);
      return records;
    } catch (_) {
      final records = await BrowserStorageService.instance.readJsonList(_registrationStorageKey);
      return records
          .whereType<Map<String, dynamic>>()
          .map(VoteAccessRecordModel.fromJson)
          .whereType<VoteAccessRecordModel>()
          .toList();
    }
  }

  Future<List<VoteAccessRecordModel>> loadRecordsForPoll(String pollId) async {
    final records = await _loadAll();
    return records.where((item) => item.pollId == pollId && item.status == 'validated').toList();
  }

  Future<List<VoteAccessRecordModel>> loadAllRecords() async {
    final records = await _loadAll();
    records.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return records;
  }

  String _generateCode() {
    final buffer = StringBuffer('INS-');
    for (var index = 0; index < 6; index++) {
      buffer.write(_codeAlphabet[_random.nextInt(_codeAlphabet.length)]);
    }
    return buffer.toString();
  }

  String _getExpiryDate() {
    final date = DateTime.now();
    return DateTime(date.year + 2, date.month, date.day).toIso8601String().split('T').first;
  }

  Future<List<VoteAccessRecordModel>> generateCodes({
    required String pollId,
    required int count,
    String? communeName,
  }) async {
    if (count <= 0) {
      return const [];
    }

    final now = DateTime.now();
    final records = List<VoteAccessRecordModel>.generate(
      count,
      (index) => VoteAccessRecordModel(
        id: 'reg-${now.microsecondsSinceEpoch}-$index',
        code: _generateCode(),
        pollId: pollId,
        createdAt: now.toIso8601String(),
        activated: false,
        hasVoted: false,
        activatedAt: null,
        votedAt: null,
        expiresAt: null,
        communeName: communeName,
        qrPayload: null,
        status: 'available',
        documentType: null,
        validatedAt: null,
        verifiedByControleurCode: null,
        verifiedByControleurLabel: null,
      ),
    );

    for (final record in records) {
      await _saveRecord(record);
    }

    return records;
  }

  Future<VoteAccessRecordModel?> validateRecord({
    required String recordId,
    required String documentType,
    String? communeName,
    String? verifiedByControleurCode,
    String? verifiedByControleurLabel,
  }) async {
    final records = await _loadAll();
    for (final record in records) {
      if (record.id != recordId) {
        continue;
      }

      final validatedAt = DateTime.now().toIso8601String().split('T').first;
      final payload = <String, dynamic>{
        'code': record.code,
        'validatedAt': validatedAt,
        'expiresAt': _getExpiryDate(),
        if ((communeName ?? record.communeName)?.isNotEmpty == true) 'commune': communeName ?? record.communeName,
      };

      final updated = record.copyWith(
        status: 'validated',
        communeName: communeName,
        documentType: documentType,
        validatedAt: validatedAt,
        expiresAt: _getExpiryDate(),
        qrPayload: jsonEncode(payload),
        verifiedByControleurCode: verifiedByControleurCode,
        verifiedByControleurLabel: verifiedByControleurLabel,
      );

      await _saveRecord(updated);
      return updated;
    }

    return null;
  }

  Future<VoteAccessRecordModel?> findByCode(String code) async {
    final normalizedCode = resolveVoteAccessCode(code);
    if (normalizedCode == null || normalizedCode.isEmpty) {
      return null;
    }

    final records = await _loadAll();
    for (final record in records) {
      final isExpired = record.expiresAt != null && DateTime.tryParse(record.expiresAt!)?.isBefore(DateTime.now()) == true;
      if (record.code.toUpperCase() == normalizedCode && record.status == 'validated' && !isExpired) {
        return record;
      }
    }

    return null;
  }

  Future<void> markActivated(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final records = await _loadAll();
    final now = DateTime.now().toIso8601String();

    for (final record in records) {
      if (record.code.toUpperCase() == normalizedCode) {
        if (record.activatedAt != null) {
          return;
        }

        await _saveRecord(record.copyWith(activatedAt: now));
        return;
      }
    }
  }

  Future<void> markVoted(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final records = await _loadAll();
    final now = DateTime.now().toIso8601String();

    for (final record in records) {
      if (record.code.toUpperCase() == normalizedCode) {
        await _saveRecord(
          record.copyWith(
            activatedAt: record.activatedAt ?? now,
            votedAt: now,
          ),
        );
        return;
      }
    }
  }
}
