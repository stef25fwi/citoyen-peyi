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
      votes: json['votes'] as int? ?? 0,
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
      totalVoters: json['totalVoters'] as int? ?? 0,
      totalVoted: json['totalVoted'] as int? ?? 0,
    );
  }
}

class VoteAccessRecordModel {
  const VoteAccessRecordModel({
    required this.id,
    required this.code,
    required this.pollId,
    required this.activated,
    required this.hasVoted,
    required this.activatedAt,
    required this.votedAt,
    required this.expiresAt,
    required this.communeName,
    required this.qrPayload,
    required this.status,
  });

  final String id;
  final String code;
  final String pollId;
  final bool activated;
  final bool hasVoted;
  final String? activatedAt;
  final String? votedAt;
  final String? expiresAt;
  final String? communeName;
  final String? qrPayload;
  final String status;

  VoteAccessRecordModel copyWith({
    String? activatedAt,
    String? votedAt,
  }) {
    return VoteAccessRecordModel(
      id: id,
      code: code,
      pollId: pollId,
      activated: activatedAt != null || this.activated,
      hasVoted: votedAt != null || hasVoted,
      activatedAt: activatedAt ?? this.activatedAt,
      votedAt: votedAt ?? this.votedAt,
      expiresAt: expiresAt,
      communeName: communeName,
      qrPayload: qrPayload,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'pollId': pollId,
        'createdAt': DateTime.now().toIso8601String(),
        'usedBy': null,
        'status': status,
        'documentType': null,
        'validatedAt': null,
        'expiresAt': expiresAt,
        'communeName': communeName,
        'qrPayload': qrPayload,
        'activatedAt': activatedAt,
        'votedAt': votedAt,
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
      activated: (json['activatedAt'] as String?) != null,
      hasVoted: (json['votedAt'] as String?) != null,
      activatedAt: json['activatedAt'] as String?,
      votedAt: json['votedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      communeName: json['communeName'] as String?,
      qrPayload: json['qrPayload'] as String?,
      status: json['status'] as String? ?? 'validated',
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
