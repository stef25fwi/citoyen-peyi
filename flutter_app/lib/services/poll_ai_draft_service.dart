import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'firebase_auth_service.dart';

class PollAiDraftServiceException implements Exception {
  const PollAiDraftServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PollAiDraft {
  const PollAiDraft({
    required this.projectTitle,
    required this.description,
    required this.question,
    required this.targetPopulation,
    required this.options,
  });

  final String projectTitle;
  final String description;
  final String question;
  final String targetPopulation;
  final List<String> options;

  Map<String, dynamic> toJson() => {
        'projectTitle': projectTitle.trim(),
        'description': description.trim(),
        'question': question.trim(),
        'targetPopulation': targetPopulation.trim(),
        'options': options
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
      };

  factory PollAiDraft.fromJson(Map<String, dynamic> json) {
    return PollAiDraft(
      projectTitle: json['projectTitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      question: json['question'] as String? ?? '',
      targetPopulation: json['targetPopulation'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class PollAiDraftService {
  PollAiDraftService._();

  static final PollAiDraftService instance = PollAiDraftService._();

  Future<PollAiDraft> rewriteDraft(PollAiDraft draft) async {
    String? token;
    try {
      token = await FirebaseAuthService.instance.currentIdToken();
    } catch (error) {
      throw PollAiDraftServiceException(
        'Session Firebase indisponible: ${error.toString()}',
      );
    }

    if (token == null || token.isEmpty) {
      throw const PollAiDraftServiceException(
        'Session Firebase manquante, reconnectez-vous.',
      );
    }

    final base = AppConfig.apiBaseUrl.trim();
    if (base.isEmpty) {
      throw const PollAiDraftServiceException(
        'Backend non configure: API_BASE_URL vide.',
      );
    }

    final uri = Uri.parse('$base/api/poll-ai/rewrite');

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(draft.toJson()),
          )
          .timeout(const Duration(seconds: 30));
    } catch (error) {
      throw PollAiDraftServiceException(
        'Assistant IA injoignable: ${error.toString()}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Assistant IA indisponible.';
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          final fromBody = payload['message'];
          if (fromBody is String && fromBody.trim().isNotEmpty) {
            message = fromBody;
          }
        }
      } catch (_) {}
      throw PollAiDraftServiceException(message);
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final proposal = payload['proposal'];
      if (proposal is! Map<String, dynamic>) {
        throw const FormatException('proposal absent');
      }
      return PollAiDraft.fromJson(proposal);
    } catch (error) {
      throw PollAiDraftServiceException(
        'Reponse IA illisible: ${error.toString()}',
      );
    }
  }
}
