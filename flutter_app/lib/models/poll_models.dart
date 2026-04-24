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

class PollModel {
  const PollModel({
    required this.id,
    required this.projectTitle,
    required this.question,
    required this.options,
    required this.openDate,
    required this.closeDate,
    required this.status,
    required this.totalVoters,
    required this.totalVoted,
  });

  final String id;
  final String projectTitle;
  final String question;
  final List<PollOptionModel> options;
  final String openDate;
  final String closeDate;
  final String status;
  final int totalVoters;
  final int totalVoted;

  PollModel copyWith({
    String? id,
    String? projectTitle,
    String? question,
    List<PollOptionModel>? options,
    String? openDate,
    String? closeDate,
    String? status,
    int? totalVoters,
    int? totalVoted,
  }) {
    return PollModel(
      id: id ?? this.id,
      projectTitle: projectTitle ?? this.projectTitle,
      question: question ?? this.question,
      options: options ?? this.options,
      openDate: openDate ?? this.openDate,
      closeDate: closeDate ?? this.closeDate,
      status: status ?? this.status,
      totalVoters: totalVoters ?? this.totalVoters,
      totalVoted: totalVoted ?? this.totalVoted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectTitle': projectTitle,
        'question': question,
        'options': options.map((item) => item.toJson()).toList(),
        'openDate': openDate,
        'closeDate': closeDate,
        'status': status,
        'totalVoters': totalVoters,
        'totalVoted': totalVoted,
      };

  static PollModel fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    return PollModel(
      id: json['id'] as String? ?? 'poll-1',
      projectTitle: json['projectTitle'] as String? ?? 'Sondage sans titre',
      question: json['question'] as String? ?? '',
      options: rawOptions.asMap().entries.map((entry) => PollOptionModel.fromJson(entry.value, entry.key)).toList(),
      openDate: json['openDate'] as String? ?? '',
      closeDate: json['closeDate'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
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
      activated: activatedAt != null || this.activated,
      hasVoted: votedAt != null || hasVoted,
      activatedAt: activatedAt ?? this.activatedAt,
      votedAt: votedAt ?? this.votedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      communeName: communeName ?? this.communeName,
      qrPayload: qrPayload ?? this.qrPayload,
      status: status ?? this.status,
      documentType: documentType ?? this.documentType,
      validatedAt: validatedAt ?? this.validatedAt,
      verifiedByControleurCode: verifiedByControleurCode ?? this.verifiedByControleurCode,
      verifiedByControleurLabel: verifiedByControleurLabel ?? this.verifiedByControleurLabel,
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
      id: json['id'] as String? ?? 'reg-${DateTime.now().millisecondsSinceEpoch}',
      code: code,
      pollId: json['pollId'] as String? ?? 'poll-1',
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
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
      return null;
    }
  }

  final uri = Uri.tryParse(trimmed);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[segments.length - 2].toLowerCase() == 'vote') {
      return Uri.decodeComponent(segments.last).toUpperCase();
    }
  }

  return trimmed.toUpperCase();
}
