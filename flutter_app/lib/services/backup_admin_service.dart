import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'firebase_auth_service.dart';

class BackupAdminException implements Exception {
  const BackupAdminException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupSnapshot {
  const BackupSnapshot({
    required this.id,
    required this.createdAt,
    required this.totalDocuments,
    required this.version,
    required this.size,
  });

  final String id;
  final String createdAt;
  final int totalDocuments;
  final int version;
  final int size;

  static BackupSnapshot fromJson(Map<String, dynamic> json) {
    return BackupSnapshot(
      id: json['id'] as String? ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      totalDocuments: (json['totalDocuments'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeletedRecord {
  const DeletedRecord({
    required this.id,
    required this.kind,
    required this.sourceCollection,
    required this.recordId,
    required this.reason,
    required this.deletedBy,
    required this.deletedAt,
    required this.data,
  });

  final String id;
  final String kind;
  final String sourceCollection;
  final String recordId;
  final String reason;
  final String deletedBy;
  final String deletedAt;
  final Map<String, dynamic> data;

  String get displayTitle {
    final label = data['label']?.toString().trim() ?? '';
    final commune = data['communeName']?.toString().trim() ??
        (data['commune'] is Map ? ((data['commune'] as Map)['name']?.toString().trim() ?? '') : '');
    if (label.isNotEmpty && commune.isNotEmpty) return '$label · $commune';
    if (label.isNotEmpty) return label;
    if (commune.isNotEmpty) return commune;
    return recordId.isNotEmpty ? recordId : id;
  }

  static DeletedRecord fromJson(Map<String, dynamic> json) {
    return DeletedRecord(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      sourceCollection: json['sourceCollection'] as String? ?? '',
      recordId: json['recordId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      deletedBy: json['deletedBy'] as String? ?? '',
      deletedAt: json['deletedAt']?.toString() ?? '',
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class RestoreCollectionReport {
  const RestoreCollectionReport({
    required this.collection,
    required this.writes,
    required this.deletes,
    required this.skipped,
  });

  final String collection;
  final int writes;
  final int deletes;
  final int skipped;
}

class RestoreReport {
  const RestoreReport({
    required this.dryRun,
    required this.mode,
    required this.force,
    required this.writes,
    required this.deletes,
    required this.skipped,
    required this.collections,
  });

  final bool dryRun;
  final String mode;
  final bool force;
  final int writes;
  final int deletes;
  final int skipped;
  final List<RestoreCollectionReport> collections;

  static RestoreReport fromJson(Map<String, dynamic> json) {
    final report = json['report'] as Map<String, dynamic>? ?? json;
    final totals = report['totals'] as Map<String, dynamic>? ?? const {};
    final rawCollections =
        report['collections'] as Map<String, dynamic>? ?? const {};
    final collections = rawCollections.entries.map((entry) {
      final value = entry.value as Map<String, dynamic>? ?? const {};
      return RestoreCollectionReport(
        collection: entry.key,
        writes: (value['writes'] as num?)?.toInt() ?? 0,
        deletes: (value['deletes'] as num?)?.toInt() ?? 0,
        skipped: (value['skipped'] as num?)?.toInt() ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.collection.compareTo(b.collection));

    return RestoreReport(
      dryRun: report['dryRun'] as bool? ?? true,
      mode: report['mode'] as String? ?? 'merge',
      force: report['force'] as bool? ?? false,
      writes: (totals['writes'] as num?)?.toInt() ?? 0,
      deletes: (totals['deletes'] as num?)?.toInt() ?? 0,
      skipped: (totals['skipped'] as num?)?.toInt() ?? 0,
      collections: collections,
    );
  }
}

class BackupAdminService {
  BackupAdminService._();

  static final BackupAdminService instance = BackupAdminService._();

  Future<List<BackupSnapshot>> listSnapshots() async {
    final payload = await _request('GET', '/api/backups');
    final raw = payload['snapshots'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BackupSnapshot.fromJson)
        .where((snapshot) => snapshot.id.isNotEmpty)
        .toList();
  }

  Future<List<DeletedRecord>> listDeletedRecords() async {
    final payload = await _request('GET', '/api/backups/deleted-records');
    final raw = payload['deletedRecords'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DeletedRecord.fromJson)
        .where((record) => record.id.isNotEmpty)
        .toList();
  }

  Future<BackupSnapshot> createSnapshot() async {
    final payload = await _request('POST', '/api/backups', body: const {});
    return BackupSnapshot.fromJson(payload);
  }

  Future<String> signedDownloadUrl(String id) async {
    final payload =
        await _request('GET', '/api/backups/${Uri.encodeComponent(id)}');
    final url = payload['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const BackupAdminException('URL de telechargement indisponible.');
    }
    return url;
  }

  Future<RestoreReport> restore(
    String id, {
    String mode = 'merge',
    bool dryRun = true,
    bool force = false,
  }) async {
    final payload = await _request(
      'POST',
      '/api/backups/${Uri.encodeComponent(id)}/restore',
      body: {'mode': mode, 'dryRun': dryRun, 'force': force},
    );
    return RestoreReport.fromJson(payload);
  }

  Future<void> deleteSnapshot(String id) async {
    await _request('DELETE', '/api/backups/${Uri.encodeComponent(id)}');
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
  }) async {
    if (AppConfig.apiBaseUrl.isEmpty) {
      throw const BackupAdminException(
          'Backend non configure (API_BASE_URL vide).');
    }

    final token =
        await FirebaseAuthService.instance.currentIdToken(forceRefresh: true);
    if (token == null || token.isEmpty) {
      throw const BackupAdminException(
          'Session super administrateur expiree. Reconnectez-vous.');
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
          break;
        default:
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(const Duration(seconds: 60));
      }
    } catch (error) {
      throw BackupAdminException('Echec de l\'appel au serveur : $error');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const BackupAdminException(
          'Acces refuse. Reconnectez-vous en super administrateur.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackupAdminException(_readError(response.body));
    }
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  String _readError(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return payload['message'] as String? ??
          payload['error'] as String? ??
          'Operation de sauvegarde impossible.';
    } catch (_) {
      return 'Operation de sauvegarde impossible.';
    }
  }
}
