import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/poll_models.dart';
import 'browser_storage_service.dart';
import 'firestore_data_service.dart';

class VoteAccessService {
  VoteAccessService._();

  static const _registrationStorageKey = 'registration_codes_v1';
  static const _registrationCollection = 'registrationCodes';
  static final VoteAccessService instance = VoteAccessService._();
  static final Random _random = Random();

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

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
