import 'dart:convert';

class PollOptionModel {
  const PollOptionModel({
    required this.id,
    required this.label,
    required this.votes,
  });

  final String id;
  final String label;
  final int votes;

  PollOptionModel copyWith({
    String? id,
    String? label,
    int? votes,
  }) {
    return PollOptionModel(
      id: id ?? this.id,
      label: label ?? this.label,
      votes: votes ?? this.votes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'votes': votes,
      };

  static PollOptionModel fromJson(Map<String, dynamic> json, int index) {
    return PollOptionModel(
      id: json['id'] as String? ?? 'opt-${index + 1}',
      label: json['label'] as String? ?? 'Option ${index + 1}',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
    );
  }
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return <String>[value.trim()];
  }
  return const <String>[];
}

String _readDateString(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is DateTime) return value.toIso8601String();
  if (value is Map<String, dynamic>) {
    final seconds = value['_seconds'] ?? value['seconds'];
    if (seconds is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        seconds.toInt() * 1000,
        isUtc: true,
      ).toIso8601String();
    }
  }
  try {
    final dynamic dynamicValue = value;
    final dynamic date = dynamicValue.toDate();
    if (date is DateTime) return date.toIso8601String();
  } catch (_) {}
  return value.toString();
}

class PollModel {
  const PollModel({
    required this.id,
    required this.projectTitle,
    this.description = '',
    required this.question,
    required this.options,
    this.photoUrls = const <String>[],
    this.targetPopulation = '',
    this.communeId = '',
    this.communeName = '',
    required this.openDate,
    required this.closeDate,
    required this.status,
    this.scheduledPublishDate = '',
    this.createdBy = '',
    this.createdAt = '',
    this.updatedAt = '',
    required this.totalVoters,
    required this.totalVoted,
  });

  final String id;
  final String projectTitle;
  final String description;
  final String question;
  final List<PollOptionModel> options;
  final List<String> photoUrls;
  String get mainPhotoUrl => photoUrls.isEmpty ? '' : photoUrls.first;
  final String targetPopulation;
  final String communeId;
  final String communeName;
  final String openDate;
  final String closeDate;
  final String status;
  final String scheduledPublishDate;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final int totalVoters;
  final int totalVoted;

  PollModel copyWith({
    String? id,
    String? projectTitle,
    String? description,
    String? question,
    List<PollOptionModel>? options,
    List<String>? photoUrls,
    String? targetPopulation,
    String? communeId,
    String? communeName,
    String? openDate,
    String? closeDate,
    String? status,
    String? scheduledPublishDate,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    int? totalVoters,
    int? totalVoted,
  }) {
    return PollModel(
      id: id ?? this.id,
      projectTitle: projectTitle ?? this.projectTitle,
      description: description ?? this.description,
      question: question ?? this.question,
      options: options ?? this.options,
      photoUrls: photoUrls ?? this.photoUrls,
      targetPopulation: targetPopulation ?? this.targetPopulation,
      communeId: communeId ?? this.communeId,
      communeName: communeName ?? this.communeName,
      openDate: openDate ?? this.openDate,
      closeDate: closeDate ?? this.closeDate,
      status: status ?? this.status,
      scheduledPublishDate: scheduledPublishDate ?? this.scheduledPublishDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalVoters: totalVoters ?? this.totalVoters,
      totalVoted: totalVoted ?? this.totalVoted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectTitle': projectTitle,
        'title': projectTitle,
        'description': description,
        'question': question,
        'options': options.map((item) => item.toJson()).toList(),
        'photoUrls': photoUrls,
        'mainPhotoUrl': mainPhotoUrl,
        'targetPopulation': targetPopulation,
        'communeId': communeId,
        'communeName': communeName,
        'openDate': openDate,
        'opensAt': openDate,
        'closeDate': closeDate,
        'closesAt': closeDate,
        'status': status,
        'scheduledPublishDate': scheduledPublishDate,
        'createdBy': createdBy,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'totalVoters': totalVoters,
        'totalVoted': totalVoted,
      };

  static PollModel fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    return PollModel(
      id: json['id'] as String? ?? 'poll-1',
      projectTitle: json['projectTitle'] as String? ??
          json['title'] as String? ??
          'Consultation sans titre',
      description: json['description'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: rawOptions
          .asMap()
          .entries
          .map((entry) => PollOptionModel.fromJson(entry.value, entry.key))
          .toList(),
      photoUrls: _readStringList(
        json['photoUrls'] ??
            json['photos'] ??
            json['imageUrls'] ??
            json['mainPhotoUrl'],
      ),
      targetPopulation: json['targetPopulation'] as String? ?? '',
      communeId: json['communeId'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      openDate: _readDateString(json['openDate'] ?? json['opensAt']),
      closeDate: _readDateString(json['closeDate'] ?? json['closesAt']),
      status: json['status'] as String? ?? 'draft',
      scheduledPublishDate:
          _readDateString(json['scheduledPublishDate'] ?? json['publishDate']),
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: _readDateString(json['createdAt']),
      updatedAt: _readDateString(json['updatedAt']),
      totalVoters: (json['totalVoters'] as num?)?.toInt() ?? 0,
      totalVoted: (json['totalVoted'] as num?)?.toInt() ?? 0,
    );
  }
}

class VoteAccessRecordModel {
  const VoteAccessRecordModel({
    required this.id,
    required this.code,
    required this.pollId,
    required this.createdAt,
    required this.activated,
    required this.hasVoted,
    required this.activatedAt,
    required this.votedAt,
    required this.expiresAt,
    required this.communeName,
    required this.qrPayload,
    required this.status,
    required this.documentType,
    required this.validatedAt,
    required this.verifiedByControleurCode,
    required this.verifiedByControleurLabel,
  });

  final String id;
  final String code;
  final String pollId;
  final String createdAt;
  final bool activated;
  final bool hasVoted;
  final String? activatedAt;
  final String? votedAt;
  final String? expiresAt;
  final String? communeName;
  final String? qrPayload;
  final String status;
  final String? documentType;
  final String? validatedAt;
  final String? verifiedByControleurCode;
  final String? verifiedByControleurLabel;

  VoteAccessRecordModel copyWith({
    String? code,
    String? pollId,
    String? createdAt,
    String? status,
    String? activatedAt,
    String? votedAt,
    String? expiresAt,
    String? communeName,
    String? qrPayload,
    String? documentType,
    String? validatedAt,
    String? verifiedByControleurCode,
    String? verifiedByControleurLabel,
  }) {
    return VoteAccessRecordModel(
      id: id,
      code: code ?? this.code,
      pollId: pollId ?? this.pollId,
      createdAt: createdAt ?? this.createdAt,
      activated: activatedAt != null || activated,
      hasVoted: votedAt != null || hasVoted,
      activatedAt: activatedAt ?? this.activatedAt,
      votedAt: votedAt ?? this.votedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      communeName: communeName ?? this.communeName,
      qrPayload: qrPayload ?? this.qrPayload,
      status: status ?? this.status,
      documentType: documentType ?? this.documentType,
      validatedAt: validatedAt ?? this.validatedAt,
      verifiedByControleurCode:
          verifiedByControleurCode ?? this.verifiedByControleurCode,
      verifiedByControleurLabel:
          verifiedByControleurLabel ?? this.verifiedByControleurLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'pollId': pollId,
        'createdAt': createdAt,
        'usedBy': null,
        'status': status,
        'documentType': documentType,
        'validatedAt': validatedAt,
        'expiresAt': expiresAt,
        'communeName': communeName,
        'qrPayload': qrPayload,
        'activatedAt': activatedAt,
        'votedAt': votedAt,
        'verifiedByControleurCode': verifiedByControleurCode,
        'verifiedByControleurLabel': verifiedByControleurLabel,
      };

  static VoteAccessRecordModel? fromJson(Map<String, dynamic> json) {
    final code = (json['code'] as String? ?? '').trim();
    if (code.isEmpty) {
      return null;
    }

    return VoteAccessRecordModel(
      id: json['id'] as String? ??
          'reg-${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      pollId: json['pollId'] as String? ?? 'poll-1',
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      activated: (json['activatedAt'] as String?) != null,
      hasVoted: (json['votedAt'] as String?) != null,
      activatedAt: json['activatedAt'] as String?,
      votedAt: json['votedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      communeName: json['communeName'] as String?,
      qrPayload: json['qrPayload'] as String?,
      status: json['status'] as String? ?? 'validated',
      documentType: json['documentType'] as String?,
      validatedAt: json['validatedAt'] as String?,
      verifiedByControleurCode: json['verifiedByControleurCode'] as String?,
      verifiedByControleurLabel: json['verifiedByControleurLabel'] as String?,
    );
  }
}

String? resolveVoteAccessCode(String rawValue) {
  final trimmed = rawValue.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  if (trimmed.startsWith('{')) {
    try {
      final parsed = jsonDecode(trimmed) as Map<String, dynamic>;
      final code = parsed['code'] as String?;
      if (code != null && code.trim().isNotEmpty) {
        return code.trim().toUpperCase();
      }
    } catch (_) {
      // Not valid JSON — fall through to plain-text handling below.
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
