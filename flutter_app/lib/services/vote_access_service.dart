import '../models/poll_models.dart';
import 'browser_storage_service.dart';

class VoteAccessService {
  VoteAccessService._();

  static const _registrationStorageKey = 'registration_codes_v1';
  static final VoteAccessService instance = VoteAccessService._();

  Future<List<VoteAccessRecordModel>> _loadAll() async {
    final records = await BrowserStorageService.instance.readJsonList(_registrationStorageKey);
    return records
        .map(VoteAccessRecordModel.fromJson)
        .whereType<VoteAccessRecordModel>()
        .toList();
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

  Future<void> markVoted(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final records = await _loadAll();
    final now = DateTime.now().toIso8601String();

    final nextRecords = records.map((record) {
      if (record.code.toUpperCase() != normalizedCode) {
        return record;
      }

      return record.copyWith(
        activatedAt: record.activatedAt ?? now,
        votedAt: now,
      );
    }).toList();

    await BrowserStorageService.instance.writeJsonList(
      _registrationStorageKey,
      nextRecords.map((item) => item.toJson()).toList(),
    );
  }
}
