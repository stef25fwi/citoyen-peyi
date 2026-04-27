import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'auth_session_store.dart';
import 'browser_storage_service.dart';
import 'firestore_data_service.dart';

enum DuplicateReason {
  lostCode('lost_code', 'Code perdu'),
  unreadableCode('unreadable_code', 'Code illisible'),
  citizenClaimsNoAccess('citizen_claims_no_access', 'La personne affirme ne jamais avoir recu son code'),
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

class CitizenSourceKeyData {
  const CitizenSourceKeyData({
    required this.sourceKeyMasked,
    required this.firstNameInitial,
    required this.lastNameInitial,
    required this.birthYear,
    required this.phoneSuffix,
  });

  final String sourceKeyMasked;
  final String firstNameInitial;
  final String lastNameInitial;
  final String birthYear;
  final String phoneSuffix;
}

class CitizenAccessCodeModel {
  const CitizenAccessCodeModel({
    required this.accessCode,
    required this.fingerprint,
    required this.sourceKeyMasked,
    required this.firstNameInitial,
    required this.lastNameInitial,
    required this.birthYear,
    required this.phoneSuffix,
    required this.communeId,
    required this.communeName,
    required this.createdByControllerId,
    required this.createdByControllerName,
    required this.createdAt,
    required this.status,
    required this.usedForLogin,
    required this.regenerationIndex,
    this.regeneratedFromCode,
    this.approvedBySuperAdminId,
    this.approvedAt,
  });

  final String accessCode;
  final String fingerprint;
  final String sourceKeyMasked;
  final String firstNameInitial;
  final String lastNameInitial;
  final String birthYear;
  final String phoneSuffix;
  final String communeId;
  final String communeName;
  final String createdByControllerId;
  final String createdByControllerName;
  final String createdAt;
  final String status;
  final bool usedForLogin;
  final String? regeneratedFromCode;
  final int regenerationIndex;
  final String? approvedBySuperAdminId;
  final String? approvedAt;

  Map<String, dynamic> toJson() => {
        'accessCode': accessCode,
        'fingerprint': fingerprint,
        'sourceKeyMasked': sourceKeyMasked,
        'firstNameInitial': firstNameInitial,
        'lastNameInitial': lastNameInitial,
        'birthYear': birthYear,
        'phoneSuffix': phoneSuffix,
        'communeId': communeId,
        'communeName': communeName,
        'createdByControllerId': createdByControllerId,
        'createdByControllerName': createdByControllerName,
        'createdAt': createdAt,
        'status': status,
        'usedForLogin': usedForLogin,
        'regeneratedFromCode': regeneratedFromCode,
        'regenerationIndex': regenerationIndex,
        'approvedBySuperAdminId': approvedBySuperAdminId,
        'approvedAt': approvedAt,
      };

  Map<String, dynamic> toFirestore() => {
        ...toJson(),
        'createdAt': Timestamp.fromDate(DateTime.parse(createdAt)),
        if (approvedAt != null) 'approvedAt': Timestamp.fromDate(DateTime.parse(approvedAt!)),
      };

  static CitizenAccessCodeModel fromJson(Map<String, dynamic> json) {
    return CitizenAccessCodeModel(
      accessCode: json['accessCode'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      sourceKeyMasked: json['sourceKeyMasked'] as String? ?? '',
      firstNameInitial: json['firstNameInitial'] as String? ?? '',
      lastNameInitial: json['lastNameInitial'] as String? ?? '',
      birthYear: json['birthYear'] as String? ?? '',
      phoneSuffix: json['phoneSuffix'] as String? ?? '',
      communeId: json['communeId'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      createdByControllerId: json['createdByControllerId'] as String? ?? '',
      createdByControllerName: json['createdByControllerName'] as String? ?? '',
      createdAt: _readDate(json['createdAt']),
      status: json['status'] as String? ?? 'active',
      usedForLogin: json['usedForLogin'] as bool? ?? false,
      regeneratedFromCode: json['regeneratedFromCode'] as String?,
      regenerationIndex: (json['regenerationIndex'] as num?)?.toInt() ?? 0,
      approvedBySuperAdminId: json['approvedBySuperAdminId'] as String?,
      approvedAt: json['approvedAt'] == null ? null : _readDate(json['approvedAt']),
    );
  }
}

class CitizenFingerprintModel {
  const CitizenFingerprintModel({
    required this.fingerprint,
    required this.sourceKeyMasked,
    required this.firstAccessCode,
    required this.latestAccessCode,
    required this.communeId,
    required this.createdAt,
    required this.updatedAt,
    required this.regenerationCount,
  });

  final String fingerprint;
  final String sourceKeyMasked;
  final String firstAccessCode;
  final String latestAccessCode;
  final String communeId;
  final String createdAt;
  final String updatedAt;
  final int regenerationCount;

  Map<String, dynamic> toJson() => {
        'fingerprint': fingerprint,
        'sourceKeyMasked': sourceKeyMasked,
        'firstAccessCode': firstAccessCode,
        'latestAccessCode': latestAccessCode,
        'communeId': communeId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'regenerationCount': regenerationCount,
      };

  Map<String, dynamic> toFirestore() => {
        ...toJson(),
        'createdAt': Timestamp.fromDate(DateTime.parse(createdAt)),
        'updatedAt': Timestamp.fromDate(DateTime.parse(updatedAt)),
      };

  static CitizenFingerprintModel fromJson(Map<String, dynamic> json) {
    return CitizenFingerprintModel(
      fingerprint: json['fingerprint'] as String? ?? '',
      sourceKeyMasked: json['sourceKeyMasked'] as String? ?? '',
      firstAccessCode: json['firstAccessCode'] as String? ?? '',
      latestAccessCode: json['latestAccessCode'] as String? ?? '',
      communeId: json['communeId'] as String? ?? '',
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
      regenerationCount: (json['regenerationCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DuplicateCodeRequestModel {
  const DuplicateCodeRequestModel({
    required this.id,
    required this.fingerprint,
    required this.sourceKeyMasked,
    required this.existingAccessCode,
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
    this.newAccessCode,
  });

  final String id;
  final String fingerprint;
  final String sourceKeyMasked;
  final String existingAccessCode;
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
  final String? newAccessCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fingerprint': fingerprint,
        'sourceKeyMasked': sourceKeyMasked,
        'existingAccessCode': existingAccessCode,
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
        'newAccessCode': newAccessCode,
      };

  Map<String, dynamic> toFirestore() => {
        ...toJson(),
        'requestedAt': Timestamp.fromDate(DateTime.parse(requestedAt)),
        if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(DateTime.parse(reviewedAt!)),
      };

  DuplicateCodeRequestModel copyWith({
    String? status,
    String? reviewedBySuperAdminId,
    String? reviewedAt,
    String? rejectionReason,
    String? newAccessCode,
  }) {
    return DuplicateCodeRequestModel(
      id: id,
      fingerprint: fingerprint,
      sourceKeyMasked: sourceKeyMasked,
      existingAccessCode: existingAccessCode,
      requestedByControllerId: requestedByControllerId,
      requestedByControllerName: requestedByControllerName,
      communeId: communeId,
      communeName: communeName,
      requestedAt: requestedAt,
      status: status ?? this.status,
      duplicateReason: duplicateReason,
      controllerComment: controllerComment,
      reviewedBySuperAdminId: reviewedBySuperAdminId ?? this.reviewedBySuperAdminId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      newAccessCode: newAccessCode ?? this.newAccessCode,
    );
  }

  static DuplicateCodeRequestModel fromJson(Map<String, dynamic> json, {String? id}) {
    return DuplicateCodeRequestModel(
      id: id ?? json['id'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      sourceKeyMasked: json['sourceKeyMasked'] as String? ?? '',
      existingAccessCode: json['existingAccessCode'] as String? ?? '',
      requestedByControllerId: json['requestedByControllerId'] as String? ?? '',
      requestedByControllerName: json['requestedByControllerName'] as String? ?? '',
      communeId: json['communeId'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      requestedAt: _readDate(json['requestedAt']),
      status: json['status'] as String? ?? 'pending',
      duplicateReason: DuplicateReason.fromValue(json['duplicateReason'] as String?),
      controllerComment: json['controllerComment'] as String?,
      reviewedBySuperAdminId: json['reviewedBySuperAdminId'] as String?,
      reviewedAt: json['reviewedAt'] == null ? null : _readDate(json['reviewedAt']),
      rejectionReason: json['rejectionReason'] as String?,
      newAccessCode: json['newAccessCode'] as String?,
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
    this.accessCode,
    this.fingerprint,
    this.sourceKeyMasked,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String communeId;
  final String communeName;
  final String controllerId;
  final String controllerName;
  final String actionType;
  final String? accessCode;
  final String? fingerprint;
  final String? sourceKeyMasked;
  final String createdAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'communeId': communeId,
        'communeName': communeName,
        'controllerId': controllerId,
        'controllerName': controllerName,
        'actionType': actionType,
        'accessCode': accessCode,
        'fingerprint': fingerprint,
        'sourceKeyMasked': sourceKeyMasked,
        'createdAt': createdAt,
        'metadata': metadata,
      };

  Map<String, dynamic> toFirestore() => {
        ...toJson(),
        'createdAt': Timestamp.fromDate(DateTime.parse(createdAt)),
      };

  static ControllerActivityLogModel fromJson(Map<String, dynamic> json, {String? id}) {
    return ControllerActivityLogModel(
      id: id ?? json['id'] as String? ?? '',
      communeId: json['communeId'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      controllerId: json['controllerId'] as String? ?? '',
      controllerName: json['controllerName'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      accessCode: json['accessCode'] as String?,
      fingerprint: json['fingerprint'] as String?,
      sourceKeyMasked: json['sourceKeyMasked'] as String?,
      createdAt: _readDate(json['createdAt']),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    );
  }
}

class CitizenCodeCreationResult {
  const CitizenCodeCreationResult.created(this.accessCode)
      : duplicateRequest = null,
        existingAccessCode = null;

  const CitizenCodeCreationResult.duplicate({
    required this.duplicateRequest,
    required this.existingAccessCode,
  }) : accessCode = null;

  final CitizenAccessCodeModel? accessCode;
  final DuplicateCodeRequestModel? duplicateRequest;
  final String? existingAccessCode;

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
  static const _fingerprintCollection = 'citizen_fingerprints';
  static const _duplicateCollection = 'duplicate_code_requests';
  static const _activityCollection = 'controller_activity_logs';

  static const _localAccessKey = 'citizen_access_codes_v1';
  static const _localFingerprintKey = 'citizen_fingerprints_v1';
  static const _localDuplicateKey = 'duplicate_code_requests_v1';
  static const _localActivityKey = 'controller_activity_logs_v1';

  CitizenSourceKeyData generateCitizenSourceKey({
    required String firstName,
    required String lastName,
    required String birthYear,
    required String phoneSuffix,
  }) {
    final firstInitial = _normalizeInitial(firstName);
    final lastInitial = _normalizeInitial(lastName);
    final year = _normalizeDigits(birthYear, expectedLength: 4);
    final suffix = _normalizeDigits(phoneSuffix, expectedLength: 2, keepLast: true);

    if (firstInitial.isEmpty || lastInitial.isEmpty || year.length != 4 || suffix.length != 2) {
      throw ArgumentError('Informations minimales invalides.');
    }

    return CitizenSourceKeyData(
      sourceKeyMasked: '$firstInitial$lastInitial$year$suffix',
      firstNameInitial: firstInitial,
      lastNameInitial: lastInitial,
      birthYear: year,
      phoneSuffix: suffix,
    );
  }

  String generateCitizenFingerprint(String sourceKeyMasked) {
    return sha256.convert(utf8.encode(sourceKeyMasked.trim().toUpperCase())).toString();
  }

  String generateCitizenAccessCode(String sourceKeyMasked) {
    return generateCitizenFingerprint(sourceKeyMasked).substring(0, 8).toUpperCase();
  }

  String generateRegeneratedAccessCode(String sourceKeyMasked, int regenerationIndex) {
    final seed = '${sourceKeyMasked.trim().toUpperCase()}-REGEN-$regenerationIndex';
    return sha256.convert(utf8.encode(seed)).toString().substring(0, 8).toUpperCase();
  }

  Future<CitizenFingerprintModel?> checkDuplicateByFingerprint(String fingerprint) async {
    final db = FirestoreDataService.instance;
    if (db != null) {
      final doc = await db.collection(_fingerprintCollection).doc(fingerprint).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return CitizenFingerprintModel.fromJson(doc.data()!);
    }

    final records = await BrowserStorageService.instance.readJsonList(_localFingerprintKey);
    for (final record in records) {
      if (record['fingerprint'] == fingerprint) {
        return CitizenFingerprintModel.fromJson(record);
      }
    }
    return null;
  }

  Future<CitizenCodeCreationResult> createCitizenAccessCode({
    required String firstName,
    required String lastName,
    required String birthYear,
    required String phoneSuffix,
    required DuplicateReason duplicateReason,
    String? controllerComment,
    AuthSession? session,
  }) async {
    final currentSession = session ?? AuthSessionStore.instance.currentSession;
    final source = generateCitizenSourceKey(
      firstName: firstName,
      lastName: lastName,
      birthYear: birthYear,
      phoneSuffix: phoneSuffix,
    );
    final fingerprint = generateCitizenFingerprint(source.sourceKeyMasked);
    final existing = await checkDuplicateByFingerprint(fingerprint);

    if (existing != null) {
      final duplicateRequest = await createDuplicateRequest(
        fingerprint: fingerprint,
        sourceKeyMasked: source.sourceKeyMasked,
        existingAccessCode: existing.latestAccessCode,
        duplicateReason: duplicateReason,
        controllerComment: controllerComment,
        session: currentSession,
      );
      await logControllerActivity(
        actionType: 'duplicate_detected',
        accessCode: existing.latestAccessCode,
        fingerprint: fingerprint,
        sourceKeyMasked: source.sourceKeyMasked,
        metadata: {'duplicateRequestId': duplicateRequest.id},
        session: currentSession,
      );
      await logControllerActivity(
        actionType: 'duplicate_request_created',
        accessCode: existing.latestAccessCode,
        fingerprint: fingerprint,
        sourceKeyMasked: source.sourceKeyMasked,
        metadata: {'duplicateRequestId': duplicateRequest.id, 'reason': duplicateReason.value},
        session: currentSession,
      );
      return CitizenCodeCreationResult.duplicate(
        duplicateRequest: duplicateRequest,
        existingAccessCode: existing.latestAccessCode,
      );
    }

    final now = DateTime.now().toIso8601String();
    final accessCode = generateCitizenAccessCode(source.sourceKeyMasked);
    final model = CitizenAccessCodeModel(
      accessCode: accessCode,
      fingerprint: fingerprint,
      sourceKeyMasked: source.sourceKeyMasked,
      firstNameInitial: source.firstNameInitial,
      lastNameInitial: source.lastNameInitial,
      birthYear: source.birthYear,
      phoneSuffix: source.phoneSuffix,
      communeId: _sessionCommuneId(currentSession),
      communeName: _sessionCommuneName(currentSession),
      createdByControllerId: _sessionActorId(currentSession),
      createdByControllerName: _sessionActorName(currentSession),
      createdAt: now,
      status: 'active',
      usedForLogin: false,
      regenerationIndex: 0,
    );
    final fingerprintModel = CitizenFingerprintModel(
      fingerprint: fingerprint,
      sourceKeyMasked: source.sourceKeyMasked,
      firstAccessCode: accessCode,
      latestAccessCode: accessCode,
      communeId: model.communeId,
      createdAt: now,
      updatedAt: now,
      regenerationCount: 0,
    );

    await _saveAccessAndFingerprint(model, fingerprintModel);
    await logControllerActivity(
      actionType: 'code_created',
      accessCode: accessCode,
      fingerprint: fingerprint,
      sourceKeyMasked: source.sourceKeyMasked,
      session: currentSession,
    );
    return CitizenCodeCreationResult.created(model);
  }

  Future<DuplicateCodeRequestModel> createDuplicateRequest({
    required String fingerprint,
    required String sourceKeyMasked,
    required String existingAccessCode,
    required DuplicateReason duplicateReason,
    String? controllerComment,
    AuthSession? session,
  }) async {
    final currentSession = session ?? AuthSessionStore.instance.currentSession;
    final now = DateTime.now().toIso8601String();
    final request = DuplicateCodeRequestModel(
      id: 'dup-${DateTime.now().microsecondsSinceEpoch}',
      fingerprint: fingerprint,
      sourceKeyMasked: sourceKeyMasked,
      existingAccessCode: existingAccessCode,
      requestedByControllerId: _sessionActorId(currentSession),
      requestedByControllerName: _sessionActorName(currentSession),
      communeId: _sessionCommuneId(currentSession),
      communeName: _sessionCommuneName(currentSession),
      requestedAt: now,
      status: 'pending',
      duplicateReason: duplicateReason,
      controllerComment: controllerComment?.trim().isEmpty == true ? null : controllerComment?.trim(),
    );

    final db = FirestoreDataService.instance;
    if (db != null) {
      final ref = await db.collection(_duplicateCollection).add(request.toFirestore());
      return DuplicateCodeRequestModel.fromJson({...request.toJson(), 'id': ref.id}, id: ref.id);
    }

    final records = await BrowserStorageService.instance.readJsonList(_localDuplicateKey);
    await BrowserStorageService.instance.writeJsonList(_localDuplicateKey, [request.toJson(), ...records]);
    return request;
  }

  Future<DuplicateCodeRequestModel?> approveDuplicateRequest({
    required String requestId,
    String? reviewedBySuperAdminId,
  }) async {
    final request = await _loadDuplicateRequest(requestId);
    if (request == null || request.status != 'pending') {
      return request;
    }

    final fingerprint = await checkDuplicateByFingerprint(request.fingerprint);
    if (fingerprint == null) {
      return null;
    }

    final now = DateTime.now().toIso8601String();
    final nextIndex = fingerprint.regenerationCount + 1;
    final newCode = generateRegeneratedAccessCode(request.sourceKeyMasked, nextIndex);
    final newAccess = CitizenAccessCodeModel(
      accessCode: newCode,
      fingerprint: request.fingerprint,
      sourceKeyMasked: request.sourceKeyMasked,
      firstNameInitial: request.sourceKeyMasked.substring(0, 1),
      lastNameInitial: request.sourceKeyMasked.substring(1, 2),
      birthYear: request.sourceKeyMasked.substring(2, 6),
      phoneSuffix: request.sourceKeyMasked.substring(6),
      communeId: request.communeId,
      communeName: request.communeName,
      createdByControllerId: request.requestedByControllerId,
      createdByControllerName: request.requestedByControllerName,
      createdAt: now,
      status: 'active',
      usedForLogin: false,
      regeneratedFromCode: fingerprint.latestAccessCode,
      regenerationIndex: nextIndex,
      approvedBySuperAdminId: reviewedBySuperAdminId ?? _sessionActorId(AuthSessionStore.instance.currentSession),
      approvedAt: now,
    );
    final updatedFingerprint = CitizenFingerprintModel(
      fingerprint: fingerprint.fingerprint,
      sourceKeyMasked: fingerprint.sourceKeyMasked,
      firstAccessCode: fingerprint.firstAccessCode,
      latestAccessCode: newCode,
      communeId: fingerprint.communeId,
      createdAt: fingerprint.createdAt,
      updatedAt: now,
      regenerationCount: nextIndex,
    );
    final updatedRequest = request.copyWith(
      status: 'approved',
      reviewedBySuperAdminId: reviewedBySuperAdminId ?? _sessionActorId(AuthSessionStore.instance.currentSession),
      reviewedAt: now,
      newAccessCode: newCode,
    );

    await _approveDuplicatePersist(
      request: updatedRequest,
      previousCode: fingerprint.latestAccessCode,
      newAccess: newAccess,
      fingerprint: updatedFingerprint,
    );
    await logControllerActivity(
      actionType: 'regeneration_approved',
      accessCode: newCode,
      fingerprint: request.fingerprint,
      sourceKeyMasked: request.sourceKeyMasked,
      metadata: {'duplicateRequestId': requestId, 'previousCode': fingerprint.latestAccessCode},
      actorOverride: (id: request.requestedByControllerId, name: request.requestedByControllerName),
      communeOverride: (id: request.communeId, name: request.communeName),
    );
    return updatedRequest;
  }

  Future<DuplicateCodeRequestModel?> rejectDuplicateRequest({
    required String requestId,
    required String rejectionReason,
    String? reviewedBySuperAdminId,
  }) async {
    final request = await _loadDuplicateRequest(requestId);
    if (request == null) {
      return null;
    }
    final updated = request.copyWith(
      status: 'rejected',
      reviewedBySuperAdminId: reviewedBySuperAdminId ?? _sessionActorId(AuthSessionStore.instance.currentSession),
      reviewedAt: DateTime.now().toIso8601String(),
      rejectionReason: rejectionReason.trim(),
    );

    await _saveDuplicateRequest(updated);
    await logControllerActivity(
      actionType: 'regeneration_rejected',
      accessCode: request.existingAccessCode,
      fingerprint: request.fingerprint,
      sourceKeyMasked: request.sourceKeyMasked,
      metadata: {'duplicateRequestId': requestId, 'reason': rejectionReason.trim()},
      actorOverride: (id: request.requestedByControllerId, name: request.requestedByControllerName),
      communeOverride: (id: request.communeId, name: request.communeName),
    );
    return updated;
  }

  Future<void> logControllerActivity({
    required String actionType,
    String? accessCode,
    String? fingerprint,
    String? sourceKeyMasked,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    AuthSession? session,
    ({String id, String name})? actorOverride,
    ({String id, String name})? communeOverride,
  }) async {
    final currentSession = session ?? AuthSessionStore.instance.currentSession;
    final log = ControllerActivityLogModel(
      id: 'log-${DateTime.now().microsecondsSinceEpoch}',
      communeId: communeOverride?.id ?? _sessionCommuneId(currentSession),
      communeName: communeOverride?.name ?? _sessionCommuneName(currentSession),
      controllerId: actorOverride?.id ?? _sessionActorId(currentSession),
      controllerName: actorOverride?.name ?? _sessionActorName(currentSession),
      actionType: actionType,
      accessCode: accessCode,
      fingerprint: fingerprint,
      sourceKeyMasked: sourceKeyMasked,
      createdAt: DateTime.now().toIso8601String(),
      metadata: metadata,
    );

    final db = FirestoreDataService.instance;
    if (db != null) {
      await db.collection(_activityCollection).add(log.toFirestore());
      return;
    }

    final records = await BrowserStorageService.instance.readJsonList(_localActivityKey);
    await BrowserStorageService.instance.writeJsonList(_localActivityKey, [log.toJson(), ...records]);
  }

  Future<List<ControllerActivityLogModel>> getControllerActivityLogs({
    ControllerActivityFilters filters = const ControllerActivityFilters(),
  }) async {
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
      final snapshot = await query.orderBy('createdAt', descending: true).limit(250).get();
      logs = snapshot.docs.map((doc) => ControllerActivityLogModel.fromJson(doc.data(), id: doc.id)).toList();
    } else {
      final records = await BrowserStorageService.instance.readJsonList(_localActivityKey);
      logs = records.map((item) => ControllerActivityLogModel.fromJson(item)).toList();
    }

    return _applyDateFilters(logs, filters)..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  Future<List<DuplicateCodeRequestModel>> getDuplicateRequestsForSuperAdmin({
    String? communeId,
    String? controllerId,
    String? status,
  }) async {
    final db = FirestoreDataService.instance;
    List<DuplicateCodeRequestModel> requests;
    if (db != null) {
      Query<Map<String, dynamic>> query = db.collection(_duplicateCollection);
      if (communeId?.isNotEmpty == true) query = query.where('communeId', isEqualTo: communeId);
      if (controllerId?.isNotEmpty == true) query = query.where('requestedByControllerId', isEqualTo: controllerId);
      if (status?.isNotEmpty == true && status != 'all') query = query.where('status', isEqualTo: status);
      final snapshot = await query.orderBy('requestedAt', descending: true).limit(200).get();
      requests = snapshot.docs.map((doc) => DuplicateCodeRequestModel.fromJson(doc.data(), id: doc.id)).toList();
    } else {
      final records = await BrowserStorageService.instance.readJsonList(_localDuplicateKey);
      requests = records.map((item) => DuplicateCodeRequestModel.fromJson(item)).toList();
    }

    return requests.where((item) {
      if (communeId?.isNotEmpty == true && item.communeId != communeId) return false;
      if (controllerId?.isNotEmpty == true && item.requestedByControllerId != controllerId) return false;
      if (status?.isNotEmpty == true && status != 'all' && item.status != status) return false;
      return true;
    }).toList()
      ..sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
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
      final codeCount = communeLogs.where((item) => item.actionType == 'code_created').length;
      final duplicateCount = communeLogs.where((item) => item.actionType == 'duplicate_detected').length;
      final pendingCount = duplicates.where((item) => item.communeId == entry.key && item.status == 'pending').length;
      final controllers = communeLogs.map((item) => item.controllerId).where((item) => item.isNotEmpty).toSet();
      result.add(
        CommuneAnalyticsModel(
          communeId: entry.key,
          communeName: communeLogs.first.communeName,
          activeControllers: controllers.length,
          codesGenerated: codeCount,
          duplicatesDetected: duplicateCount,
          pendingRequests: pendingCount,
          duplicateRate: codeCount + duplicateCount == 0 ? 0 : duplicateCount / (codeCount + duplicateCount),
          lastCodeGeneratedAt: communeLogs.isEmpty ? null : communeLogs.first.createdAt,
        ),
      );
    }
    return result..sort((left, right) => left.communeName.compareTo(right.communeName));
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
      byController[log.controllerName] = (byController[log.controllerName] ?? 0) + 1;
    }

    return ControllerActivityAnalytics(
      logs: logs,
      totalCodesGenerated: logs.where((item) => item.actionType == 'code_created').length,
      duplicatesDetected: logs.where((item) => item.actionType == 'duplicate_detected').length,
      regenerationRequests: logs.where((item) => item.actionType == 'duplicate_request_created').length,
      regenerationsApproved: logs.where((item) => item.actionType == 'regeneration_approved').length,
      regenerationsRejected: logs.where((item) => item.actionType == 'regeneration_rejected').length,
      loginCodesUsed: logs.where((item) => item.actionType == 'login_code_used').length,
      activityByDay: byDay,
      activityByController: byController,
      lastActivity: logs.isEmpty ? null : logs.first,
    );
  }

  Future<void> _saveAccessAndFingerprint(
    CitizenAccessCodeModel access,
    CitizenFingerprintModel fingerprint,
  ) async {
    final db = FirestoreDataService.instance;
    if (db != null) {
      await db.runTransaction((transaction) async {
        final fingerprintRef = db.collection(_fingerprintCollection).doc(fingerprint.fingerprint);
        final existing = await transaction.get(fingerprintRef);
        if (existing.exists) {
          throw StateError('Un code existe deja pour cette empreinte.');
        }
        transaction.set(db.collection(_accessCollection).doc(access.accessCode), access.toFirestore());
        transaction.set(fingerprintRef, fingerprint.toFirestore());
      });
      return;
    }

    final accessRecords = await BrowserStorageService.instance.readJsonList(_localAccessKey);
    final fingerprintRecords = await BrowserStorageService.instance.readJsonList(_localFingerprintKey);
    if (fingerprintRecords.any((item) => item['fingerprint'] == fingerprint.fingerprint)) {
      throw StateError('Un code existe deja pour cette empreinte.');
    }
    await BrowserStorageService.instance.writeJsonList(_localAccessKey, [access.toJson(), ...accessRecords]);
    await BrowserStorageService.instance.writeJsonList(_localFingerprintKey, [fingerprint.toJson(), ...fingerprintRecords]);
  }

  Future<DuplicateCodeRequestModel?> _loadDuplicateRequest(String requestId) async {
    final db = FirestoreDataService.instance;
    if (db != null) {
      final doc = await db.collection(_duplicateCollection).doc(requestId).get();
      if (!doc.exists || doc.data() == null) return null;
      return DuplicateCodeRequestModel.fromJson(doc.data()!, id: doc.id);
    }
    final records = await BrowserStorageService.instance.readJsonList(_localDuplicateKey);
    for (final item in records) {
      if (item['id'] == requestId) return DuplicateCodeRequestModel.fromJson(item);
    }
    return null;
  }

  Future<void> _saveDuplicateRequest(DuplicateCodeRequestModel request) async {
    final db = FirestoreDataService.instance;
    if (db != null) {
      await db.collection(_duplicateCollection).doc(request.id).set(request.toFirestore(), SetOptions(merge: true));
      return;
    }
    final records = await BrowserStorageService.instance.readJsonList(_localDuplicateKey);
    final next = records.map((item) => item['id'] == request.id ? request.toJson() : item).toList();
    await BrowserStorageService.instance.writeJsonList(_localDuplicateKey, next);
  }

  Future<void> _approveDuplicatePersist({
    required DuplicateCodeRequestModel request,
    required String previousCode,
    required CitizenAccessCodeModel newAccess,
    required CitizenFingerprintModel fingerprint,
  }) async {
    final db = FirestoreDataService.instance;
    if (db != null) {
      final batch = db.batch();
      batch.set(db.collection(_duplicateCollection).doc(request.id), request.toFirestore(), SetOptions(merge: true));
      batch.set(db.collection(_accessCollection).doc(newAccess.accessCode), newAccess.toFirestore());
      batch.set(db.collection(_fingerprintCollection).doc(fingerprint.fingerprint), fingerprint.toFirestore(), SetOptions(merge: true));
      batch.set(db.collection(_accessCollection).doc(previousCode), {'status': 'replaced'}, SetOptions(merge: true));
      await batch.commit();
      return;
    }

    final requests = await BrowserStorageService.instance.readJsonList(_localDuplicateKey);
    final access = await BrowserStorageService.instance.readJsonList(_localAccessKey);
    final fingerprints = await BrowserStorageService.instance.readJsonList(_localFingerprintKey);
    await BrowserStorageService.instance.writeJsonList(
      _localDuplicateKey,
      requests.map((item) => item['id'] == request.id ? request.toJson() : item).toList(),
    );
    await BrowserStorageService.instance.writeJsonList(
      _localAccessKey,
      [
        newAccess.toJson(),
        ...access.map((item) => item['accessCode'] == previousCode ? {...item, 'status': 'replaced'} : item),
      ],
    );
    await BrowserStorageService.instance.writeJsonList(
      _localFingerprintKey,
      fingerprints.map((item) => item['fingerprint'] == fingerprint.fingerprint ? fingerprint.toJson() : item).toList(),
    );
  }

  List<ControllerActivityLogModel> _applyDateFilters(
    List<ControllerActivityLogModel> logs,
    ControllerActivityFilters filters,
  ) {
    return logs.where((log) {
      final created = DateTime.tryParse(log.createdAt);
      if (created == null) return false;
      if (filters.startDate != null && created.isBefore(filters.startDate!)) return false;
      if (filters.endDate != null && created.isAfter(filters.endDate!.add(const Duration(days: 1)))) return false;
      return true;
    }).toList();
  }

  String _normalizeInitial(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.isEmpty) return '';
    return String.fromCharCode(trimmed.runes.first);
  }

  String _normalizeDigits(String value, {required int expectedLength, bool keepLast = false}) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < expectedLength) return digits;
    return keepLast ? digits.substring(digits.length - expectedLength) : digits.substring(0, expectedLength);
  }

  String _sessionActorId(AuthSession? session) => session?.id ?? session?.code ?? 'unknown-controller';

  String _sessionActorName(AuthSession? session) => session?.label ?? 'Controleur';

  String _sessionCommuneId(AuthSession? session) => session?.commune?.code ?? session?.commune?.name ?? 'unknown-commune';

  String _sessionCommuneName(AuthSession? session) => session?.commune?.name ?? 'Commune non renseignee';
}

String _readDate(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  if (value is String && value.isNotEmpty) return value;
  return DateTime.now().toIso8601String();
}