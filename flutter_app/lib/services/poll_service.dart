import 'dart:convert';

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
    final records =
        await BrowserStorageService.instance.readJsonList(_pollStorageKey);
    return records
        .whereType<Map<String, dynamic>>()
        .map(PollModel.fromJson)
        .toList();
  }

  Future<List<PollModel>> loadPolls() async {
    final session = AuthSessionStore.instance.currentSession;
    final isSuperAdmin = session?.isSuperAdmin == true;
    final isAuthenticated = session?.isCommuneAdmin == true ||
        session?.isController == true ||
        isSuperAdmin;
    // Le super admin n'est rattache a aucune commune : portee vide => toutes
    // les consultations (toutes communes) lui sont retournees.
    final communeScope = isAuthenticated && !isSuperAdmin
        ? (session?.commune?.code ?? session?.commune?.name ?? '')
        : '';

    // Pour les sessions authentifiees, on prefere l'API backend (autorisee
    // par le token Firebase) qui voit immediatement les nouvelles
    // consultations meme si la lecture Firestore client est bloquee (App
    // Check, regle, etc.).
    if (isAuthenticated) {
      try {
        final response = await _request('GET', '/api/polls');
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          final rawList = payload['polls'];
          if (rawList is List) {
            final polls = rawList
                .whereType<Map<String, dynamic>>()
                .map(PollModel.fromJson)
                .toList()
              ..sort((left, right) => right.openDate.compareTo(left.openDate));
            await _writeLocalPolls(polls);
            return _filterByCommuneScope(polls, communeScope);
          }
        }
      } catch (_) {
        // Repli sur Firestore puis cache local ci-dessous.
      }
    }

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
    List<String> photoUrls = const <String>[],
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
      'photoUrls': photoUrls
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(),
      'openDate': openDate,
      'closeDate': closeDate,
      'totalVoters': totalVoters,
      'communeId': session?.commune?.code,
      'communeName': session?.commune?.name,
    });
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const PollServiceException(
          'Reponse backend invalide lors de la creation.');
    }
    final pollPayload = payload['poll'];
    if (pollPayload is! Map<String, dynamic>) {
      throw const PollServiceException(
          'Reponse backend sans consultation creee.');
    }
    try {
      final poll = PollModel.fromJson(pollPayload);
      // Met aussi a jour le cache local immediatement pour que le retour
      // au dashboard affiche la consultation meme si la lecture suivante
      // (Firestore/API) est legerement decalee ou bloquee.
      try {
        final existing = await _loadLocalPolls();
        final merged = <PollModel>[
          poll,
          ...existing.where((item) => item.id != poll.id),
        ]..sort((left, right) => right.openDate.compareTo(left.openDate));
        await _writeLocalPolls(merged);
      } catch (_) {}
      return poll;
    } catch (error) {
      throw PollServiceException(
          'Consultation creee mais reponse illisible: $error');
    }
  }

  Future<PollModel?> updatePoll({
    required String pollId,
    required String projectTitle,
    String description = '',
    required String question,
    required List<String> options,
    List<String>? photoUrls,
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
      if (photoUrls != null)
        'photoUrls': photoUrls
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList(),
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

  Future<http.Response> _post(String path, Object body) =>
      _request('POST', path, body: body);
  Future<http.Response> _patch(String path, Object body) =>
      _request('PATCH', path, body: body);
  Future<http.Response> _delete(String path) => _request('DELETE', path);

  Future<http.Response> _request(String method, String path,
      {Object? body}) async {
    String? token;
    try {
      token = await FirebaseAuthService.instance.currentIdToken();
    } catch (error) {
      throw PollServiceException(
          'Session Firebase indisponible: ${error.toString()}');
    }
    if (token == null || token.isEmpty) {
      throw const PollServiceException(
          'Session Firebase manquante, reconnectez-vous.');
    }
    final base = AppConfig.apiBaseUrl.trim();
    if (base.isEmpty) {
      throw const PollServiceException(
          'Backend non configure (API_BASE_URL vide).');
    }
    final uri = Uri.parse('$base$path');
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 12));
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(const Duration(seconds: 12));
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(body ?? const {}))
              .timeout(const Duration(seconds: 12));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 10));
          break;
        default:
          throw PollServiceException('Méthode HTTP non supportée: $method');
      }
    } catch (error) {
      if (error is PollServiceException) rethrow;
      throw PollServiceException('Backend injoignable: ${error.toString()}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Opération impossible (HTTP ${response.statusCode}).';
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          final fromBody = parsed['message'];
          if (fromBody is String && fromBody.trim().isNotEmpty) {
            message = fromBody;
          }
        }
      } catch (_) {}
      throw PollServiceException(message);
    }
    return response;
  }

  List<PollModel> _filterByCommuneScope(
      List<PollModel> polls, String communeScope) {
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
