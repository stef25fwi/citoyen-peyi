import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/poll_models.dart';
import 'auth_session_store.dart';
import 'browser_storage_service.dart';
import 'firebase_auth_service.dart';
import 'firestore_data_service.dart';

class PollServiceException implements Exception {
  const PollServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PollService {
  PollService._();

  static const _pollStorageKey = 'polls_v1';
  static const _pollCollection = 'polls';
  static final PollService instance = PollService._();

  Future<void> _writeLocalPolls(List<PollModel> polls) {
    return BrowserStorageService.instance.writeJsonList(
      _pollStorageKey,
      polls.map((item) => item.toJson()).toList(),
    );
  }

  Future<List<PollModel>> _loadLocalPolls() async {
    final records = await BrowserStorageService.instance.readJsonList(_pollStorageKey);
    return records
        .whereType<Map<String, dynamic>>()
        .map(PollModel.fromJson)
        .toList();
  }

  Future<List<PollModel>> loadPolls() async {
    final session = AuthSessionStore.instance.currentSession;
    final communeScope = (session?.isCommuneAdmin == true || session?.isController == true)
        ? (session?.commune?.code ?? session?.commune?.name ?? '')
        : '';

    final db = FirestoreDataService.instance;
    if (db == null) {
      final polls = await _loadLocalPolls();
      return _filterByCommuneScope(polls, communeScope);
    }

    try {
      final snapshot = await db.collection(_pollCollection).get();
      if (snapshot.docs.isEmpty) {
        final polls = await _loadLocalPolls();
        return _filterByCommuneScope(polls, communeScope);
      }

      final polls = snapshot.docs
          .map((item) => PollModel.fromJson(item.data()))
          .toList()
        ..sort((left, right) => right.openDate.compareTo(left.openDate));
      await _writeLocalPolls(polls);
      return _filterByCommuneScope(polls, communeScope);
    } catch (_) {
      final polls = await _loadLocalPolls();
      return _filterByCommuneScope(polls, communeScope);
    }
  }

  Future<PollModel?> loadPollById(String pollId) async {
    final polls = await loadPolls();
    for (final poll in polls) {
      if (poll.id == pollId) {
        return poll;
      }
    }
    return null;
  }

  Future<PollModel> createPoll({
    required String projectTitle,
    String description = '',
    required String question,
    required List<String> options,
    String targetPopulation = '',
    required String openDate,
    required String closeDate,
    required int totalVoters,
  }) async {
    final session = AuthSessionStore.instance.currentSession;
    final response = await _post('/api/polls', {
      'projectTitle': projectTitle.trim(),
      'description': description.trim(),
      'question': question.trim(),
      'options': options
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .map((label) => {'label': label})
          .toList(),
      'targetPopulation': targetPopulation.trim(),
      'openDate': openDate,
      'closeDate': closeDate,
      'totalVoters': totalVoters,
      'communeId': session?.commune?.code,
      'communeName': session?.commune?.name,
    });
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return PollModel.fromJson(payload['poll'] as Map<String, dynamic>);
  }

  Future<PollModel?> updatePoll({
    required String pollId,
    required String projectTitle,
    String description = '',
    required String question,
    required List<String> options,
    String targetPopulation = '',
    required String openDate,
    required String closeDate,
    required int totalVoters,
  }) async {
    final polls = await loadPolls();
    final existing = polls.where((poll) => poll.id == pollId).firstOrNull;
    if (existing == null) return null;
    final canEditOptions = existing.totalVoted == 0;
    await _patch('/api/polls/$pollId', {
      'projectTitle': projectTitle.trim(),
      'description': description.trim(),
      'question': question.trim(),
      'targetPopulation': targetPopulation.trim(),
      'openDate': openDate,
      'closeDate': closeDate,
      'totalVoters': totalVoters,
      if (canEditOptions)
        'options': options
            .map((label) => label.trim())
            .where((label) => label.isNotEmpty)
            .map((label) => {'label': label})
            .toList(),
    });
    return loadPollById(pollId);
  }

  Future<PollModel?> publishPoll(String pollId) async {
    await _post('/api/polls/$pollId/publish', const <String, dynamic>{});
    return loadPollById(pollId);
  }

  Future<PollModel?> closePoll(String pollId) async {
    await _post('/api/polls/$pollId/close', const <String, dynamic>{});
    return loadPollById(pollId);
  }

  Future<PollModel?> archivePoll(String pollId) async {
    await _post('/api/polls/$pollId/archive', const <String, dynamic>{});
    return loadPollById(pollId);
  }

  Future<void> deletePoll(String pollId) async {
    await _delete('/api/polls/$pollId');
  }

  Future<http.Response> _post(String path, Object body) => _request('POST', path, body: body);
  Future<http.Response> _patch(String path, Object body) => _request('PATCH', path, body: body);
  Future<http.Response> _delete(String path) => _request('DELETE', path);

  Future<http.Response> _request(String method, String path, {Object? body}) async {
    final token = await FirebaseAuthService.instance.currentIdToken();
    if (token == null || token.isEmpty) {
      throw const PollServiceException('Session Firebase manquante, reconnectez-vous.');
    }
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    late http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await http.post(uri, headers: headers, body: jsonEncode(body ?? const {})).timeout(const Duration(seconds: 12));
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: jsonEncode(body ?? const {})).timeout(const Duration(seconds: 12));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
          break;
        default:
          throw PollServiceException('Methode HTTP non supportee: $method');
      }
    } catch (error) {
      if (error is PollServiceException) rethrow;
      throw const PollServiceException('Backend injoignable. Reessayez plus tard.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Operation impossible.';
      try {
        message = (jsonDecode(response.body) as Map<String, dynamic>)['message'] as String? ?? message;
      } catch (_) {}
      throw PollServiceException(message);
    }
    return response;
  }

  List<PollModel> _filterByCommuneScope(List<PollModel> polls, String communeScope) {
    if (communeScope.isEmpty) {
      return polls;
    }

    return polls.where((poll) {
      if (poll.communeId.isNotEmpty) {
        return poll.communeId == communeScope;
      }
      if (poll.communeName.isNotEmpty) {
        return poll.communeName.toLowerCase() == communeScope.toLowerCase();
      }
      return true;
    }).toList();
  }
}
