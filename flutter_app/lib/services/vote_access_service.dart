import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/poll_models.dart';
import 'firebase_auth_service.dart';

class VoteAccessException implements Exception {
  const VoteAccessException(this.message, {this.errorCode = 'UNKNOWN'});

  final String message;
  final String errorCode;

  @override
  String toString() => message;
}

/// Question d'un questionnaire multi-etapes cote citoyen.
class EligiblePollQuestion {
  const EligiblePollQuestion({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.multiple = false,
    this.options = const <EligiblePollOption>[],
  });

  final String id;
  final String title;
  final String subtitle;
  final bool multiple;
  final List<EligiblePollOption> options;

  static EligiblePollQuestion fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return EligiblePollQuestion(
      id: (json['id'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      subtitle: (json['subtitle'] as String? ?? '').trim(),
      multiple: json['multiple'] == true,
      options: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(EligiblePollOption.fromJson)
          .where((option) => option.id.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class EligiblePollOption {
  const EligiblePollOption({
    required this.id,
    required this.label,
    this.icon = '',
    this.photoUrls = const <String>[],
  });

  final String id;
  final String label;
  final String icon;
  final List<String> photoUrls;

  static EligiblePollOption fromJson(Map<String, dynamic> json) {
    return EligiblePollOption(
      id: (json['id'] as String? ?? '').trim(),
      label: (json['label'] as String? ?? '').trim(),
      icon: (json['icon'] as String? ?? '').trim(),
      photoUrls: (json['photoUrls'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class EligiblePollModel {
  const EligiblePollModel({
    required this.pollId,
    required this.title,
    required this.status,
    required this.hasVoted,
    this.accessToken = '',
    this.description = '',
    this.question = '',
    this.photoUrls = const <String>[],
    this.options = const [],
    this.questions = const [],
  });

  final String pollId;
  final String title;
  final String status;
  final bool hasVoted;
  final String accessToken;
  final String description;
  final String question;
  final List<String> photoUrls;
  final List<EligiblePollOption> options;
  final List<EligiblePollQuestion> questions;

  /// Questionnaire effectif : questions du backend, sinon pseudo-question
  /// unique batie sur question/options historiques (meme convention que le
  /// backend avec l'identifiant 'main').
  List<EligiblePollQuestion> get effectiveQuestions {
    if (questions.isNotEmpty) return questions;
    return [
      EligiblePollQuestion(
        id: 'main',
        title: question,
        options: options,
      ),
    ];
  }

  static EligiblePollModel fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    final rawQuestions = json['questions'] as List<dynamic>? ?? const [];
    return EligiblePollModel(
      pollId: json['pollId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ??
          json['projectTitle'] as String? ??
          'Consultation',
      status: json['status'] as String? ?? 'open',
      hasVoted: json['hasVoted'] as bool? ?? false,
      accessToken: json['accessToken'] as String? ?? '',
      description: json['description'] as String? ?? '',
      question: json['question'] as String? ?? '',
      photoUrls: (json['photoUrls'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
      options: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(EligiblePollOption.fromJson)
          .where((option) => option.id.isNotEmpty)
          .toList(growable: false),
      questions: rawQuestions
          .whereType<Map<String, dynamic>>()
          .map(EligiblePollQuestion.fromJson)
          .where((q) => q.id.isNotEmpty && q.options.isNotEmpty)
          .toList(growable: false),
    );
  }
}

/// Reponse a une question d'un questionnaire multi-etapes.
class PollAnswer {
  const PollAnswer({required this.questionId, required this.optionIds});

  final String questionId;
  final List<String> optionIds;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'optionIds': optionIds,
      };
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

VoteAccessValidationResult _validationFromPayload(
  Map<String, dynamic> payload,
  List<EligiblePollModel> eligiblePolls,
) {
  return VoteAccessValidationResult(
    accessToken: payload['accessToken'] as String? ?? '',
    accessCodeId: payload['accessCodeId'] as String? ?? '',
    communeId: payload['communeId'] as String? ?? '',
    communeName: payload['communeName'] as String? ?? '',
    eligiblePolls: eligiblePolls,
  );
}

class VoteSubmitResult {
  const VoteSubmitResult({required this.receiptId, required this.message});

  final String receiptId;
  final String message;
}

class VoteAccessService {
  VoteAccessService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final VoteAccessService instance = VoteAccessService();

  Future<VoteAccessValidationResult> validateCode(String rawCode,
      {String? pollId}) async {
    final code = parseCodeOrQrUrl(rawCode);
    if (code == null || code.isEmpty) {
      throw const VoteAccessException('Code citoyen requis.',
          errorCode: 'INVALID_CODE');
    }

    try {
      final appCheckToken =
          await FirebaseAuthService.instance.currentAppCheckToken();
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/vote-access/validate'),
            headers: {
              'Content-Type': 'application/json',
              if (appCheckToken != null && appCheckToken.isNotEmpty)
                'X-Firebase-AppCheck': appCheckToken,
            },
            body: jsonEncode({
              'code': code,
              if (pollId?.trim().isNotEmpty == true) 'pollId': pollId!.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));
      final payload = jsonDecode(response.body) as Map<String, dynamic>;

      // Un code valide pour une commune sans consultation ouverte renvoie 409
      // NO_OPEN_POLL : on le traite comme une validation réussie avec zéro
      // consultation afin d'ouvrir quand même l'espace citoyen (page bienvenue).
      if (!pollIdSpecified(pollId) &&
          response.statusCode == 409 &&
          payload['errorCode'] == 'NO_OPEN_POLL') {
        return _validationFromPayload(payload, const <EligiblePollModel>[]);
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          payload['ok'] != true) {
        throw VoteAccessException(
          payload['message'] as String? ?? 'Code inconnu, expiré ou désactivé.',
          errorCode: payload['errorCode'] as String? ?? 'INVALID_CODE',
        );
      }
      final eligiblePolls =
          (payload['eligiblePolls'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(EligiblePollModel.fromJson)
              .where((poll) => poll.pollId.isNotEmpty)
              .toList();

      return _validationFromPayload(payload, eligiblePolls);
    } on VoteAccessException {
      rethrow;
    } catch (_) {
      throw const VoteAccessException(
          'Validation sécurisée indisponible. Réessayez plus tard.',
          errorCode: 'NETWORK_ERROR');
    }
  }

  Future<VoteSubmitResult> submitVote({
    required String accessToken,
    required String pollId,
    String optionId = '',
    List<PollAnswer> answers = const [],
  }) async {
    try {
      final appCheckToken =
          await FirebaseAuthService.instance.currentAppCheckToken();
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/vote-access/submit'),
            headers: {
              'Content-Type': 'application/json',
              if (appCheckToken != null && appCheckToken.isNotEmpty)
                'X-Firebase-AppCheck': appCheckToken,
            },
            body: jsonEncode({
              'accessToken': accessToken,
              'pollId': pollId,
              if (optionId.isNotEmpty) 'optionId': optionId,
              if (answers.isNotEmpty)
                'answers': answers.map((a) => a.toJson()).toList(),
              'source': 'web',
            }),
          )
          .timeout(const Duration(seconds: 12));
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          payload['ok'] != true) {
        throw VoteAccessException(
          payload['message'] as String? ?? 'Enregistrement du vote impossible.',
          errorCode: payload['errorCode'] as String? ?? 'SUBMIT_FAILED',
        );
      }
      return VoteSubmitResult(
        receiptId: payload['receiptId'] as String? ?? '',
        message: payload['message'] as String? ??
            'Votre vote est enregistre anonymement.',
      );
    } on VoteAccessException {
      rethrow;
    } catch (_) {
      throw const VoteAccessException(
          'Réseau indisponible. Votre vote n’a pas été enregistré.',
          errorCode: 'NETWORK_ERROR');
    }
  }

  String? parseCodeOrQrUrl(String rawValue) => resolveVoteAccessCode(rawValue);

  bool pollIdSpecified(String? pollId) => pollId?.trim().isNotEmpty == true;
}
