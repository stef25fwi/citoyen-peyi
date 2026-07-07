import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_session_store.dart';
import 'firebase_auth_service.dart';
import 'firestore_data_service.dart';

enum DuplicateReason {
  lostCode('lost_code', 'Code perdu'),
  unreadableCode('unreadable_code', 'Code illisible'),
  citizenClaimsNoAccess('citizen_claims_no_access',
      'La personne affirme ne jamais avoir reçu son code'),
  newCitizenCodeCreation(
      'new_citizen_code_creation', 'Nouvelle création de code citoyen'),
  controllerError('controller_error', 'Erreur de saisie'),
  other('other', 'Autre');

  const DuplicateReason(this.value, this.label);

  final String value;
  final String label;

  static DuplicateReason fromValue(String? value) {
    return DuplicateReason.values.firstWhere(
      (item) => item.value == value,
      orElse: () => DuplicateReason.other,
    );
  }
}

class CitizenAccessCodeModel {
  const CitizenAccessCodeModel({
    required this.accessCode,
    required this.communeId,
    required this.communeName,
    required this.createdByControllerId,
    required this.createdByControllerName,
    required this.createdAt,
    required this.status,
    required this.usedForLogin,
    required this.regenerationIndex,
    required this.pollScope,
    required this.eligiblePollIds,
    required this.identityDocumentChecked,
    required this.addressProofChecked,
    required this.communeEligibilityChecked,
    this.regeneratedFromCode,
    this.approvedBySuperAdminId,
    this.approvedAt,
  });

  final String accessCode;
  final String communeId;
  final String communeName;
  final String createdByControllerId;
  final String createdByControllerName;
  final String createdAt;
  final String status;
  final bool usedForLogin;
  final String? regeneratedFromCode;
  final int regenerationIndex;
  final String pollScope;
  final List<String> eligiblePollIds;
  final bool identityDocumentChecked;
  final bool addressProofChecked;
  final bool communeEligibilityChecked;
  final String? approvedBySuperAdminId;
  final String? approvedAt;

  CitizenAccessCodeModel copyWith({
    String? status,
    bool? usedForLogin,
    String? approvedBySuperAdminId,
    String? approvedAt,
    String? pollScope,
    List<String>? eligiblePollIds,
    bool? identityDocumentChecked,
    bool? addressProofChecked,
    bool? communeEligibilityChecked,
  }) {
    return CitizenAccessCodeModel(
      accessCode: accessCode,
      communeId: communeId,
      communeName: communeName,
      createdByControllerId: createdByControllerId,
      createdByControllerName: createdByControllerName,
      createdAt: createdAt,
      status: status ?? this.status,
      usedForLogin: usedForLogin ?? this.usedForLogin,
      regeneratedFromCode: regeneratedFromCode,
      regenerationIndex: regenerationIndex,
      pollScope: pollScope ?? this.pollScope,
      eligiblePollIds: eligiblePollIds ?? this.eligiblePollIds,
      identityDocumentChecked:
          identityDocumentChecked ?? this.identityDocumentChecked,
      addressProofChecked: addressProofChecked ?? this.addressProofChecked,
      communeEligibilityChecked:
          communeEligibilityChecked ?? this.communeEligibilityChecked,
      approvedBySuperAdminId:
          approvedBySuperAdminId ?? this.approvedBySuperAdminId,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayCodeMasked': accessCode,
        'communeId': communeId,
        'communeName': communeName,
        'createdByControllerId': createdByControllerId,
        'createdByControllerName': createdByControllerName,
        'createdAt': createdAt,
        'status': status,
        'usedForLogin': usedForLogin,
        'regenerationIndex': regenerationIndex,
        'pollScope': pollScope,
        'eligiblePollIds': eligiblePollIds,
        'identityDocumentChecked': identityDocumentChecked,
        'addressProofChecked': addressProofChecked,
        'communeEligibilityChecked': communeEligibilityChecked,
        'approvedBySuperAdminId': approvedBySuperAdminId,
        'approvedAt': approvedAt,
      };

  Map<String, dynamic> toFirestore() => {
        'communeId': communeId,
        'communeName': communeName,
        'createdByControllerId': createdByControllerId,
        'createdByControllerName': createdByControllerName,
        'createdAt': Timestamp.fromDate(DateTime.parse(createdAt)),
        'status': status,
        'usedForLogin': usedForLogin,
        'regenerationIndex': regenerationIndex,
        'pollScope': pollScope,
        'eligiblePollIds': eligiblePollIds,
        'identityDocumentChecked': identityDocumentChecked,
        'addressProofChecked': addressProofChecked,
        'communeEligibilityChecked': communeEligibilityChecked,
        'approvedBySuperAdminId': approvedBySuperAdminId,
        if (approvedAt != null)
          'approvedAt': Timestamp.fromDate(DateTime.parse(approvedAt!)),
      };

  static CitizenAccessCodeModel fromJson(Map<String, dynamic> json) {
    final metadata =
        json['metadata'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final verification = metadata['verification'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final rawEligiblePollIds = json['eligiblePollIds'] as List<dynamic>? ??
        metadata['eligiblePollIds'] as List<dynamic>? ??
        const [];

    return CitizenAccessCodeModel(
      accessCode: json['accessCode'] as String? ??
          json['displayCodeMasked'] as String? ??
          '',
      communeId: json['communeId'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      createdByControllerId: json['createdByControllerId'] as String? ?? '',
      createdByControllerName: json['createdByControllerName'] as String? ?? '',
      createdAt: _readDate(json['createdAt']),
      status: json['status'] as String? ?? 'active',
      usedForLogin: json['usedForLogin'] as bool? ?? false,
      regeneratedFromCode: json['regeneratedFromCode'] as String?,
      regenerationIndex: (json['regenerationIndex'] as num?)?.toInt() ?? 0,
      pollScope: json['pollScope'] as String? ??
          metadata['pollScope'] as String? ??
          'all_open_polls',
      eligiblePollIds: rawEligiblePollIds
          .map((item) => '$item')
          .where((item) => item.isNotEmpty)
          .toList(),
      identityDocumentChecked: json['identityDocumentChecked'] as bool? ??
          verification['hasIdentityDocument'] as bool? ??
          false,
      addressProofChecked: json['addressProofChecked'] as bool? ??
          verification['hasResidenceProof'] as bool? ??
          false,
      communeEligibilityChecked: json['communeEligibilityChecked'] as bool? ??
          verification['communeEligibilityChecked'] as bool? ??
          false,
      approvedBySuperAdminId: json['approvedBySuperAdminId'] as String?,
      approvedAt:
          json['approvedAt'] == null ? null : _readDate(json['approvedAt']),
    );
  }
}

class DuplicateCodeRequestModel {
  const DuplicateCodeRequestModel({
    required this.id,
    required this.requestedByControllerId,
    required this.requestedByControllerName,
    required this.communeId,
    required this.communeName,
    required this.requestedAt,
    required this.status,
    required this.duplicateReason,
    this.controllerComment,
    this.reviewedBySuperAdminId,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String requestedByControllerId;
  final String requestedByControllerName;
  final String communeId;
  final String communeName;
  final String requestedAt;
  final String status;
  final DuplicateReason duplicateReason;
  final String? controllerComment;
  final String? reviewedBySuperAdminId;
  final String? reviewedAt;
  final String? rejectionReason;

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestedByControllerId': requestedByControllerId,
        'requestedByControllerName': requestedByControllerName,
        'communeId': communeId,
        'communeName': communeName,
        'requestedAt': requestedAt,
        'status': status,
        'duplicateReason': duplicateReason.value,
        'controllerComment': controllerComment,
        'reviewedBySuperAdminId': reviewedBySuperAdminId,
        'reviewedAt': reviewedAt,
        'rejectionReason': rejectionReason,
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'requestedByControllerId': requestedByControllerId,
        'requestedByControllerName': requestedByControllerName,
        'communeId': communeId,
        'communeName': communeName,
        'requestedAt': Timestamp.fromDate(DateTime.parse(requestedAt)),
        'status': status,
        'duplicateReason': duplicateReason.value,
        'controllerComment': controllerComment,
        'reviewedBySuperAdminId': reviewedBySuperAdminId,
        if (reviewedAt != null)
          'reviewedAt': Timestamp.fromDate(DateTime.parse(reviewedAt!)),
        'rejectionReason': rejectionReason,
      };

  DuplicateCodeRequestModel copyWith({
    String? status,
    String? reviewedBySuperAdminId,
    String? reviewedAt,
    String? rejectionReason,
  }) {
    return DuplicateCodeRequestModel(
      id: id,
      requestedByControllerId: requestedByControllerId,
      requestedByControllerName: requestedByControllerName,
      communeId: communeId,
      communeName: communeName,
      requestedAt: requestedAt,
      status: status ?? this.status,
      duplicateReason: duplicateReason,
      controllerComment: controllerComment,
      reviewedBySuperAdminId:
          reviewedBySuperAdminId ?? this.reviewedBySuperAdminId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  static DuplicateCodeRequestModel fromJson(Map<String, dynamic> json,
      {String? id}) {
    return DuplicateCodeRequestModel(
      id: id ?? json['id'] as String? ?? '',
      requestedByControllerId: json['requestedByControllerId'] as String? ?? '',
      requestedByControllerName:
          json['requestedByControllerName'] as String? ?? '',
      communeId: json['communeId'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      requestedAt: _readDate(json['requestedAt']),
      status: json['status'] as String? ?? 'pending',
      duplicateReason:
          DuplicateReason.fromValue(json['duplicateReason'] as String?),
      controllerComment: json['controllerComment'] as String?,
      reviewedBySuperAdminId: json['reviewedBySuperAdminId'] as String?,
      reviewedAt:
          json['reviewedAt'] == null ? null : _readDate(json['reviewedAt']),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}

class ControllerActivityLogModel {
  const ControllerActivityLogModel({
    required this.id,
    required this.communeId,
    required this.communeName,
    required this.controllerId,
    required this.controllerName,
    required this.actionType,
    required this.createdAt,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String communeId;
  final String communeName;
  final String controllerId;
  final String controllerName;
  final String actionType;
  final String createdAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'communeId': communeId,
        'communeName': communeName,
        'controllerId': controllerId,
        'controllerName': controllerName,
        'actionType': actionType,
        'createdAt': createdAt,
        'metadata': metadata,
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'communeId': communeId,
        'communeName': communeName,
        'controllerId': controllerId,
        'controllerName': controllerName,
        'actionType': actionType,
        'createdAt': Timestamp.fromDate(DateTime.parse(createdAt)),
        'metadata': metadata,
      };

  static ControllerActivityLogModel fromJson(Map<String, dynamic> json,
      {String? id}) {
    return ControllerActivityLogModel(
      id: id ?? json['id'] as String? ?? '',
      communeId: json['communeId'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      controllerId: json['controllerId'] as String? ?? '',
      controllerName: json['controllerName'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      createdAt: _readDate(json['createdAt']),
      metadata: (json['metadata'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }
}

class CitizenCodeCreationResult {
  const CitizenCodeCreationResult.created(this.accessCode)
      : duplicateRequest = null,
        hasDuplicateRequest = false;

  const CitizenCodeCreationResult.duplicate({
    required this.duplicateRequest,
  })  : accessCode = null,
        hasDuplicateRequest = true;

  final CitizenAccessCodeModel? accessCode;
  final DuplicateCodeRequestModel? duplicateRequest;
  final bool hasDuplicateRequest;

  bool get created => accessCode != null;
}

class ControllerActivityFilters {
  const ControllerActivityFilters({
    this.communeId,
    this.controllerId,
    this.actionType,
    this.startDate,
    this.endDate,
  });

  final String? communeId;
  final String? controllerId;
  final String? actionType;
  final DateTime? startDate;
  final DateTime? endDate;
}

class ControllerActivityAnalytics {
  const ControllerActivityAnalytics({
    required this.logs,
    required this.totalCodesGenerated,
    required this.duplicatesDetected,
    required this.regenerationRequests,
    required this.regenerationsApproved,
    required this.regenerationsRejected,
    required this.loginCodesUsed,
    required this.activityByDay,
    required this.activityByController,
    this.lastActivity,
  });

  final List<ControllerActivityLogModel> logs;
  final int totalCodesGenerated;
  final int duplicatesDetected;
  final int regenerationRequests;
  final int regenerationsApproved;
  final int regenerationsRejected;
  final int loginCodesUsed;
  final Map<String, int> activityByDay;
  final Map<String, int> activityByController;
  final ControllerActivityLogModel? lastActivity;
}

class CommuneAnalyticsModel {
  const CommuneAnalyticsModel({
    required this.communeId,
    required this.communeName,
    required this.activeControllers,
    required this.codesGenerated,
    required this.duplicatesDetected,
    required this.pendingRequests,
    required this.duplicateRate,
    this.lastCodeGeneratedAt,
  });

  final String communeId;
  final String communeName;
  final int activeControllers;
  final int codesGenerated;
  final int duplicatesDetected;
  final int pendingRequests;
  final double duplicateRate;
  final String? lastCodeGeneratedAt;
}

class CitizenAccessCodeService {
  CitizenAccessCodeService._();

  static final CitizenAccessCodeService instance = CitizenAccessCodeService._();

  static const _accessCollection = 'citizen_access_codes';
  static const _duplicateCollection = 'duplicate_code_requests';
  static const _activityCollection = 'controller_activity_logs';

  Future<CitizenCodeCreationResult> createCitizenAccessCode({
    required String firstName,
    required String lastName,
    required String birthYear,
    required String phoneSuffix,
    required bool identityDocumentChecked,
    required bool addressProofChecked,
    required bool communeEligibilityChecked,
    required DuplicateReason duplicateReason,
    String? selectedPollId,
    String? controllerComment,
    AuthSession? session,
  }) async {
    final backendResult = await _createCitizenAccessCodeOnBackend(
      firstName: firstName,
      lastName: lastName,
      birthYear: birthYear,
      phoneSuffix: phoneSuffix,
      identityDocumentChecked: identityDocumentChecked,
      addressProofChecked: addressProofChecked,
      communeEligibilityChecked: communeEligibilityChecked,
      duplicateReason: duplicateReason,
      selectedPollId: selectedPollId,
      controllerComment: controllerComment,
    );
    if (backendResult != null) {
      return backendResult;
    }

    throw StateError(
        'Validation de sécurité indisponible. Réessayez plus tard.');
  }

  Future<CitizenAccessCodeModel?> findActiveAccessCode(String rawCode) async {
    final normalizedCode = _normalizeAccessCode(rawCode);
    if (normalizedCode.isEmpty) return null;
    return null;
  }

  Future<List<CitizenAccessCodeModel>> loadAccessCodes({
    String? communeId,
    String? controllerId,
    int limit = 250,
  }) async {
    final db = FirestoreDataService.instance;
    List<CitizenAccessCodeModel> records;

    if (db != null) {
      try {
        Query<Map<String, dynamic>> query = db.collection(_accessCollection);
        if (communeId?.isNotEmpty == true) {
          query = query.where('communeId', isEqualTo: communeId);
        }
        if (controllerId?.isNotEmpty == true) {
          query = query.where('createdByControllerId', isEqualTo: controllerId);
        }
        final snapshot = await query
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
        records = snapshot.docs
            .map((doc) => CitizenAccessCodeModel.fromJson(doc.data()))
            .toList();
      } catch (_) {
        records = <CitizenAccessCodeModel>[];
      }
    } else {
      records = <CitizenAccessCodeModel>[];
    }

    return records.where((item) {
      if (communeId?.isNotEmpty == true && item.communeId != communeId) {
        return false;
      }
      if (controllerId?.isNotEmpty == true &&
          item.createdByControllerId != controllerId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  Future<List<CitizenAccessCodeModel>>
      loadAccessCodesForCurrentController() async {
    final session = AuthSessionStore.instance.currentSession;
    final controllerId = _sessionActorId(session);
    final records =
        await loadAccessCodes(controllerId: controllerId, limit: 100);
    return records
        .where((item) =>
            item.createdByControllerId == controllerId ||
            session?.mode == 'fallback')
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  Future<List<CitizenAccessCodeModel>>
      loadAccessCodesForCurrentCommune() async {
    final session = AuthSessionStore.instance.currentSession;
    final communeId = _sessionCommuneId(session);
    final db = FirestoreDataService.instance;
    List<CitizenAccessCodeModel> records;

    if (db != null) {
      try {
        Query<Map<String, dynamic>> query = db.collection(_accessCollection);
        if (communeId.isNotEmpty && communeId != 'unknown-commune') {
          query = query.where('communeId', isEqualTo: communeId);
        }
        final snapshot =
            await query.orderBy('createdAt', descending: true).limit(250).get();
        records = snapshot.docs
            .map((doc) => CitizenAccessCodeModel.fromJson(doc.data()))
            .toList();
      } catch (_) {
        records = <CitizenAccessCodeModel>[];
      }
    } else {
      records = <CitizenAccessCodeModel>[];
    }

    if (communeId.isEmpty ||
        communeId == 'unknown-commune' ||
        session?.mode == 'fallback') {
      return records
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    }

    return records.where((item) => item.communeId == communeId).toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  Future<void> markAccessCodeUsedForPublicVote(String accessCode) async {
    final normalizedCode = _normalizeAccessCode(accessCode);
    if (normalizedCode.isEmpty) return;
    return;
  }

  Future<DuplicateCodeRequestModel> createDuplicateRequest({
    required DuplicateReason duplicateReason,
    String? controllerComment,
    AuthSession? session,
  }) async {
    throw StateError(
        'Validation de sécurité indisponible. Réessayez plus tard.');
  }

  Future<DuplicateCodeRequestModel?> approveDuplicateRequest({
    required String requestId,
    String? reviewedBySuperAdminId,
  }) async {
    final backendRequest = await _postDuplicateDecisionOnBackend(
      requestId: requestId,
      approve: true,
    );
    if (backendRequest != null) {
      return backendRequest;
    }
    throw StateError(
        'Validation de sécurité indisponible. Réessayez plus tard.');
  }

  Future<DuplicateCodeRequestModel?> rejectDuplicateRequest({
    required String requestId,
    required String rejectionReason,
    String? reviewedBySuperAdminId,
  }) async {
    final backendRequest = await _postDuplicateDecisionOnBackend(
      requestId: requestId,
      approve: false,
      rejectionReason: rejectionReason,
    );
    if (backendRequest != null) {
      return backendRequest;
    }
    throw StateError(
        'Validation de sécurité indisponible. Réessayez plus tard.');
  }

  Future<void> logControllerActivity({
    required String actionType,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    AuthSession? session,
    ({String id, String name})? actorOverride,
    ({String id, String name})? communeOverride,
  }) async {
    return;
  }

  Future<List<ControllerActivityLogModel>> getControllerActivityLogs({
    ControllerActivityFilters filters = const ControllerActivityFilters(),
  }) async {
    final backendLogs =
        await _getControllerActivityLogsFromBackend(filters: filters);
    if (backendLogs != null) {
      return _applyDateFilters(backendLogs, filters)
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    }

    final db = FirestoreDataService.instance;
    List<ControllerActivityLogModel> logs;

    if (db != null) {
      Query<Map<String, dynamic>> query = db.collection(_activityCollection);
      if (filters.communeId?.isNotEmpty == true) {
        query = query.where('communeId', isEqualTo: filters.communeId);
      }
      if (filters.controllerId?.isNotEmpty == true) {
        query = query.where('controllerId', isEqualTo: filters.controllerId);
      }
      if (filters.actionType?.isNotEmpty == true) {
        query = query.where('actionType', isEqualTo: filters.actionType);
      }
      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(250).get();
      logs = snapshot.docs
          .map((doc) =>
              ControllerActivityLogModel.fromJson(doc.data(), id: doc.id))
          .toList();
    } else {
      logs = <ControllerActivityLogModel>[];
    }

    return _applyDateFilters(logs, filters)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  Future<List<DuplicateCodeRequestModel>> getDuplicateRequestsForSuperAdmin({
    String? communeId,
    String? controllerId,
    String? status,
  }) async {
    final backendRequests = await _getDuplicateRequestsFromBackend(
      communeId: communeId,
      controllerId: controllerId,
      status: status,
    );
    if (backendRequests != null) {
      return backendRequests;
    }

    final db = FirestoreDataService.instance;
    List<DuplicateCodeRequestModel> requests;
    if (db != null) {
      Query<Map<String, dynamic>> query = db.collection(_duplicateCollection);
      if (communeId?.isNotEmpty == true) {
        query = query.where('communeId', isEqualTo: communeId);
      }
      if (controllerId?.isNotEmpty == true) {
        query = query.where('requestedByControllerId', isEqualTo: controllerId);
      }
      if (status?.isNotEmpty == true && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      final snapshot =
          await query.orderBy('requestedAt', descending: true).limit(200).get();
      requests = snapshot.docs
          .map((doc) =>
              DuplicateCodeRequestModel.fromJson(doc.data(), id: doc.id))
          .toList();
    } else {
      requests = <DuplicateCodeRequestModel>[];
    }

    return requests.where((item) {
      if (communeId?.isNotEmpty == true && item.communeId != communeId) {
        return false;
      }
      if (controllerId?.isNotEmpty == true &&
          item.requestedByControllerId != controllerId) {
        return false;
      }
      if (status?.isNotEmpty == true &&
          status != 'all' &&
          item.status != status) {
        return false;
      }
      return true;
    }).toList()
      ..sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
  }

  Future<List<DuplicateCodeRequestModel>>
      getDuplicateRequestsForCurrentController({
    String? status,
  }) {
    final session = AuthSessionStore.instance.currentSession;
    return getDuplicateRequestsForSuperAdmin(
      controllerId: _sessionActorId(session),
      status: status,
    );
  }

  Future<List<CommuneAnalyticsModel>> getCommuneAnalyticsForSuperAdmin() async {
    final logs = await getControllerActivityLogs();
    final duplicates = await getDuplicateRequestsForSuperAdmin();
    final byCommune = <String, List<ControllerActivityLogModel>>{};
    for (final log in logs) {
      byCommune.putIfAbsent(log.communeId, () => []).add(log);
    }

    final result = <CommuneAnalyticsModel>[];
    for (final entry in byCommune.entries) {
      final communeLogs = entry.value;
      final codeCount =
          communeLogs.where((item) => item.actionType == 'code_created').length;
      final duplicateCount = communeLogs
          .where((item) => item.actionType == 'duplicate_detected')
          .length;
      final pendingCount = duplicates
          .where(
              (item) => item.communeId == entry.key && item.status == 'pending')
          .length;
      final controllers = communeLogs
          .map((item) => item.controllerId)
          .where((item) => item.isNotEmpty)
          .toSet();
      result.add(
        CommuneAnalyticsModel(
          communeId: entry.key,
          communeName: communeLogs.first.communeName,
          activeControllers: controllers.length,
          codesGenerated: codeCount,
          duplicatesDetected: duplicateCount,
          pendingRequests: pendingCount,
          duplicateRate: codeCount + duplicateCount == 0
              ? 0
              : duplicateCount / (codeCount + duplicateCount),
          lastCodeGeneratedAt:
              communeLogs.isEmpty ? null : communeLogs.first.createdAt,
        ),
      );
    }
    return result
      ..sort((left, right) => left.communeName.compareTo(right.communeName));
  }

  Future<ControllerActivityAnalytics> getControllerAnalytics({
    ControllerActivityFilters filters = const ControllerActivityFilters(),
  }) async {
    final logs = await getControllerActivityLogs(filters: filters);
    final byDay = <String, int>{};
    final byController = <String, int>{};
    for (final log in logs) {
      final day = log.createdAt.split('T').first;
      byDay[day] = (byDay[day] ?? 0) + 1;
      byController[log.controllerName] =
          (byController[log.controllerName] ?? 0) + 1;
    }

    return ControllerActivityAnalytics(
      logs: logs,
      totalCodesGenerated:
          logs.where((item) => item.actionType == 'code_created').length,
      duplicatesDetected:
          logs.where((item) => item.actionType == 'duplicate_detected').length,
      regenerationRequests: logs
          .where((item) => item.actionType == 'duplicate_request_created')
          .length,
      regenerationsApproved: logs
          .where((item) => item.actionType == 'regeneration_approved')
          .length,
      regenerationsRejected: logs
          .where((item) => item.actionType == 'regeneration_rejected')
          .length,
      loginCodesUsed:
          logs.where((item) => item.actionType == 'login_code_used').length,
      activityByDay: byDay,
      activityByController: byController,
      lastActivity: logs.isEmpty ? null : logs.first,
    );
  }

  List<ControllerActivityLogModel> _applyDateFilters(
    List<ControllerActivityLogModel> logs,
    ControllerActivityFilters filters,
  ) {
    return logs.where((log) {
      final created = DateTime.tryParse(log.createdAt);
      if (created == null) {
        return false;
      }
      if (filters.startDate != null && created.isBefore(filters.startDate!)) {
        return false;
      }
      if (filters.endDate != null &&
          created.isAfter(filters.endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  String _normalizeAccessCode(String rawCode) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('{')) {
      try {
        final parsed = jsonDecode(trimmed) as Map<String, dynamic>;
        final code =
            parsed['accessCode'] as String? ?? parsed['code'] as String?;
        if (code != null && code.trim().isNotEmpty) {
          return code.trim().toUpperCase();
        }
      } catch (_) {
        return '';
      }
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final queryCode = uri.queryParameters['code'];
      if (queryCode != null && queryCode.trim().isNotEmpty) {
        return queryCode.trim().toUpperCase();
      }

      final segments = uri.pathSegments;
      if (segments.length >= 2 &&
          segments[segments.length - 2].toLowerCase() == 'vote') {
        return Uri.decodeComponent(segments.last).toUpperCase();
      }
    }
    return trimmed.toUpperCase();
  }

  String _sessionActorId(AuthSession? session) =>
      session?.id ?? 'unknown-controller';

  String _sessionCommuneId(AuthSession? session) =>
      session?.commune?.code ?? session?.commune?.name ?? 'unknown-commune';

  bool get _secureBackendMode =>
      AppConfig.apiBaseUrl.isNotEmpty &&
      !AppConfig.apiBaseUrl.contains('localhost') &&
      !AppConfig.apiBaseUrl.contains('127.0.0.1');

  Future<CitizenCodeCreationResult?> _createCitizenAccessCodeOnBackend({
    required String firstName,
    required String lastName,
    required String birthYear,
    required String phoneSuffix,
    required bool identityDocumentChecked,
    required bool addressProofChecked,
    required bool communeEligibilityChecked,
    required DuplicateReason duplicateReason,
    String? selectedPollId,
    String? controllerComment,
  }) async {
    final payload = await _authorizedBackendRequest(
      method: 'POST',
      path: '/api/citizen-access/codes',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'birthYear': birthYear,
        'phoneSuffix': phoneSuffix,
        'citizenFingerprintInput': {
          'firstNameInitial': firstName,
          'lastNameInitial': lastName,
          'birthYear': birthYear,
          'phoneLastTwo': phoneSuffix,
        },
        'duplicateReason': duplicateReason.value,
        'consultationScope': selectedPollId?.trim().isNotEmpty == true
            ? 'single_poll'
            : 'all_open_polls',
        'consultationIds': selectedPollId?.trim().isNotEmpty == true
            ? <String>[selectedPollId!.trim()]
            : const <String>[],
        'verification': {
          'hasIdentityDocument': identityDocumentChecked,
          'hasResidenceProof': addressProofChecked,
          'communeEligibilityChecked': communeEligibilityChecked,
        },
        'controllerComment': controllerComment,
      },
    );
    if (payload == null) return null;

    final status = payload['status'] as String?;
    if (status == 'created') {
      final access = CitizenAccessCodeModel.fromJson(
          payload['accessCode'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
      return CitizenCodeCreationResult.created(access);
    }
    if (status == 'duplicate_request_created') {
      final request = DuplicateCodeRequestModel.fromJson(
          payload['duplicateRequest'] as Map<String, dynamic>? ??
              const <String, dynamic>{});
      return CitizenCodeCreationResult.duplicate(
        duplicateRequest: request,
      );
    }
    return null;
  }

  Future<DuplicateCodeRequestModel?> _postDuplicateDecisionOnBackend({
    required String requestId,
    required bool approve,
    String? rejectionReason,
  }) async {
    final payload = await _authorizedBackendRequest(
      method: 'POST',
      path:
          '/api/citizen-access/duplicates/$requestId/${approve ? 'approve' : 'reject'}',
      body: approve
          ? const <String, dynamic>{}
          : {'rejectionReason': rejectionReason},
    );
    if (payload == null) return null;
    return DuplicateCodeRequestModel.fromJson(
        payload['request'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
        id: requestId);
  }

  Future<List<DuplicateCodeRequestModel>?> _getDuplicateRequestsFromBackend({
    String? communeId,
    String? controllerId,
    String? status,
  }) async {
    final payload = await _authorizedBackendRequest(
      method: 'GET',
      path: '/api/citizen-access/duplicates',
      query: {
        if (communeId?.isNotEmpty == true) 'communeId': communeId!,
        if (controllerId?.isNotEmpty == true) 'controllerId': controllerId!,
        if (status?.isNotEmpty == true) 'status': status!,
      },
    );
    if (payload == null) return null;
    final records = payload['requests'] as List<dynamic>? ?? const [];
    return records
        .whereType<Map<String, dynamic>>()
        .map((item) =>
            DuplicateCodeRequestModel.fromJson(item, id: item['id'] as String?))
        .toList()
      ..sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
  }

  Future<List<ControllerActivityLogModel>?>
      _getControllerActivityLogsFromBackend({
    required ControllerActivityFilters filters,
  }) async {
    final payload = await _authorizedBackendRequest(
      method: 'GET',
      path: '/api/citizen-access/activity',
      query: {
        if (filters.communeId?.isNotEmpty == true)
          'communeId': filters.communeId!,
        if (filters.controllerId?.isNotEmpty == true)
          'controllerId': filters.controllerId!,
        if (filters.actionType?.isNotEmpty == true)
          'actionType': filters.actionType!,
        if (filters.startDate != null)
          'startDate': filters.startDate!.toIso8601String(),
        if (filters.endDate != null)
          'endDate': filters.endDate!.toIso8601String(),
      },
    );
    if (payload == null) return null;
    final records = payload['logs'] as List<dynamic>? ?? const [];
    return records
        .whereType<Map<String, dynamic>>()
        .map((item) => ControllerActivityLogModel.fromJson(item,
            id: item['id'] as String?))
        .toList();
  }

  Future<Map<String, dynamic>?> _authorizedBackendRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String> query = const {},
  }) async {
    if (!AppConfig.isFirebaseConfigured || AppConfig.apiBaseUrl.isEmpty) {
      return null;
    }

    // Jeton robuste (gere le repli REST Safari/iPad ou FirebaseAuth.currentUser
    // est null mais un jeton ID valide existe).
    String? token;
    try {
      token =
          await FirebaseAuthService.instance.currentIdToken(forceRefresh: true);
    } catch (_) {
      token = null;
    }
    if (token == null || token.isEmpty) {
      if (_secureBackendMode) {
        throw StateError(
            'Session expirée. Reconnectez-vous (espace agent) puis réessayez.');
      }
      return null;
    }

    var uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Cold start Cloud Run : apres inactivite, la 1re requete peut renvoyer 503
    // (aucune instance disponible) AVANT d'atteindre le handler -> le code n'est
    // pas cree, le reessai est donc sûr. Timeout large pour absorber le
    // demarrage a froid. Un POST n'est PAS rejoue sur erreur reseau/timeout
    // (risque de double creation) : seul le 503 declenche un reessai.
    const maxAttempts = 3;
    const timeout = Duration(seconds: 25);
    StateError? pendingError;

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      late http.Response response;
      try {
        response = method == 'GET'
            ? await http.get(uri, headers: headers).timeout(timeout)
            : await http
                .post(uri,
                    headers: headers,
                    body: jsonEncode(body ?? const <String, dynamic>{}))
                .timeout(timeout);
      } catch (error) {
        // Erreur reseau/timeout/CORS. GET : rejouable ; POST : on remonte.
        if (method == 'GET' && attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        if (_secureBackendMode) {
          throw StateError('Service momentanément injoignable. Réessayez dans '
              'un instant. ($error)');
        }
        return null;
      }

      // 503 = cold start / instance indisponible : requete non traitee -> sûr.
      if (response.statusCode == 503 && attempt < maxAttempts) {
        pendingError =
            StateError(_readBackendError(response.body, response.statusCode));
        await Future.delayed(Duration(milliseconds: 600 * attempt));
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(_readBackendError(response.body, response.statusCode));
      }
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw StateError(
            'Réponse backend illisible (HTTP ${response.statusCode}).');
      }
    }

    if (pendingError != null) throw pendingError;
    if (_secureBackendMode) {
      throw StateError('Service indisponible (réessayez dans un instant).');
    }
    return null;
  }

  String _readBackendError(String body, [int? status]) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      final message =
          (payload['message'] as String?) ?? (payload['error'] as String?);
      if (message != null && message.trim().isNotEmpty) return message;
    } catch (_) {
      // Corps non JSON : on retombe sur un message generique avec le statut.
    }
    return status != null
        ? 'Opération backend impossible (HTTP $status).'
        : 'Opération backend impossible.';
  }
}

String _readDate(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  if (value is String && value.isNotEmpty) return value;
  return DateTime.now().toIso8601String();
}
