import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/support_message.dart';
import '../models/support_ticket.dart';
import 'auth_session_store.dart';
import 'firebase_auth_service.dart';

class SupportTicketException implements Exception {
  const SupportTicketException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SupportTicketService {
  SupportTicketService._();

  static final SupportTicketService instance = SupportTicketService._();
  static const _pollInterval = Duration(seconds: 8);

  Stream<List<SupportTicket>> watchAdminTickets(String communeId) {
    return _poll(_fetchTickets);
  }

  Stream<List<SupportTicket>> watchAllTicketsForSuperAdmin() {
    return _poll(_fetchTickets);
  }

  Stream<List<SupportTicket>> watchUnreadTicketsForSuperAdmin() {
    return watchAllTicketsForSuperAdmin().map(
      (tickets) => tickets
          .where((ticket) => ticket.unreadForSuperAdmin)
          .toList(growable: false),
    );
  }

  Stream<List<SupportTicket>> watchUnreadTicketsForAdmin(String communeId) {
    return watchAdminTickets(communeId).map(
      (tickets) => tickets
          .where((ticket) => ticket.unreadForAdmin)
          .toList(growable: false),
    );
  }

  Stream<SupportTicket?> watchTicket(String ticketId) {
    return _poll(() => _fetchTicket(ticketId));
  }

  Stream<List<SupportMessage>> watchTicketMessages(String ticketId) {
    return _poll(() => _fetchMessages(ticketId));
  }

  Future<String> createTicket({
    required String subject,
    required String category,
    required String priority,
    required String message,
  }) async {
    final normalizedSubject = subject.trim();
    final normalizedMessage = message.trim();
    if (normalizedSubject.length < 5) {
      throw const SupportTicketException(
          'Le sujet doit contenir au moins 5 caractères.');
    }
    if (normalizedMessage.length < 10) {
      throw const SupportTicketException(
          'Le message doit contenir au moins 10 caractères.');
    }
    if (!supportTicketCategories.contains(category)) {
      throw const SupportTicketException('Catégorie obligatoire.');
    }
    if (!supportTicketPriorities.contains(priority)) {
      throw const SupportTicketException('Priorité obligatoire.');
    }

    final session = AuthSessionStore.instance.currentSession;
    if (session?.isCommuneAdmin != true || session?.isSuperAdmin == true) {
      throw const SupportTicketException(
          'Session administrateur communal requise.');
    }
    final communeId = (session?.commune?.code?.trim().isNotEmpty == true
            ? session!.commune!.code
            : session?.commune?.name)
        ?.trim();
    final communeName = session?.commune?.name.trim() ?? communeId ?? '';
    if (communeId == null || communeId.isEmpty || communeName.isEmpty) {
      throw const SupportTicketException('Commune rattachée introuvable.');
    }

    final user = _currentFirebaseUser;
    final response = await _request(
      'POST',
      '/api/support/tickets',
      body: {
        'subject': normalizedSubject,
        'category': category,
        'priority': priority,
        'message': normalizedMessage,
        'communeName': communeName,
        'createdByName': session?.label ??
            user?.displayName ??
            'Administrateur communal',
        'createdByEmail': user?.email ?? '',
      },
    );
    final payload = _decodeMap(response.body);
    return _readString(payload['ticketId']);
  }

  Future<void> sendMessage({
    required String ticketId,
    required String message,
  }) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.length < 2) {
      throw const SupportTicketException(
          'Le message doit contenir au moins 2 caractères.');
    }
    final session = AuthSessionStore.instance.currentSession;
    final isSuperAdmin = session?.isSuperAdmin == true;
    final isAdmin = session?.isCommuneAdmin == true;
    if (!isSuperAdmin && !isAdmin) {
      throw const SupportTicketException('Session authentifiée requise.');
    }
    final user = _currentFirebaseUser;
    await _request(
      'POST',
      '/api/support/tickets/${Uri.encodeComponent(ticketId)}/messages',
      body: {
        'message': normalizedMessage,
        'senderName': session?.label ??
            user?.displayName ??
            (isSuperAdmin ? 'Super administrateur' : 'Administrateur communal'),
        'senderEmail': user?.email ?? '',
      },
    );
  }

  Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    if (!supportTicketStatuses.contains(status)) {
      throw const SupportTicketException('Statut invalide.');
    }
    final session = AuthSessionStore.instance.currentSession;
    if (session?.isSuperAdmin != true) {
      throw const SupportTicketException('Réservé au super administrateur.');
    }
    await _request(
      'PATCH',
      '/api/support/tickets/${Uri.encodeComponent(ticketId)}/status',
      body: {'status': status},
    );
  }

  Future<void> markTicketReadByAdmin(String ticketId) async {
    await _request(
      'POST',
      '/api/support/tickets/${Uri.encodeComponent(ticketId)}/read',
      body: const <String, dynamic>{},
    );
  }

  Future<void> markTicketReadBySuperAdmin(String ticketId) async {
    await _request(
      'POST',
      '/api/support/tickets/${Uri.encodeComponent(ticketId)}/read',
      body: const <String, dynamic>{},
    );
  }

  Future<void> closeTicket(String ticketId) {
    return updateTicketStatus(ticketId: ticketId, status: 'ferme');
  }

  Future<void> reopenTicket(String ticketId) {
    return updateTicketStatus(ticketId: ticketId, status: 'en_cours');
  }

  Stream<T> _poll<T>(Future<T> Function() loader) {
    // Flux resilient base sur un StreamController (un async* ne peut pas emettre
    // une erreur sans se terminer) :
    //  - echec du TOUT PREMIER chargement -> on propage l'erreur pour que
    //    l'ecran affiche son etat « indisponible / reessayer » ;
    //  - apres au moins un succes, un incident transitoire (cold start, jeton en
    //    refresh, micro-coupure) est ignore : on garde la derniere valeur a
    //    l'ecran (pas de clignotement « indisponible ») ;
    //  - dans tous les cas le flux reste ouvert et continue d'interroger, donc
    //    il se retablit automatiquement des que le backend repond.
    late StreamController<T> controller;
    Timer? timer;
    var hasValue = false;
    var loading = false;

    Future<void> tick() async {
      if (loading || controller.isClosed) return;
      loading = true;
      try {
        final value = await loader();
        if (!controller.isClosed) {
          hasValue = true;
          controller.add(value);
        }
      } catch (error, stackTrace) {
        if (!hasValue && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        loading = false;
      }
    }

    controller = StreamController<T>(
      onListen: () {
        tick();
        timer = Timer.periodic(_pollInterval, (_) => tick());
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );
    return controller.stream;
  }

  Future<List<SupportTicket>> _fetchTickets() async {
    final response = await _request('GET', '/api/support/tickets');
    final payload = _decodeMap(response.body);
    final rawTickets = payload['tickets'];
    if (rawTickets is! List) return const <SupportTicket>[];
    final tickets = rawTickets
        .whereType<Map>()
        .map((item) => SupportTicket.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
    tickets.sort((left, right) {
      final urgent = (right.isUrgent ? 1 : 0).compareTo(left.isUrgent ? 1 : 0);
      if (urgent != 0) return urgent;
      return right.updatedAt.compareTo(left.updatedAt);
    });
    return tickets;
  }

  Future<SupportTicket?> _fetchTicket(String ticketId) async {
    final response = await _request(
      'GET',
      '/api/support/tickets/${Uri.encodeComponent(ticketId)}',
      allowNotFound: true,
    );
    if (response.statusCode == 404) return null;
    final payload = _decodeMap(response.body);
    final rawTicket = payload['ticket'];
    if (rawTicket is! Map) return null;
    return SupportTicket.fromJson(Map<String, dynamic>.from(rawTicket));
  }

  Future<List<SupportMessage>> _fetchMessages(String ticketId) async {
    final response = await _request(
      'GET',
      '/api/support/tickets/${Uri.encodeComponent(ticketId)}/messages',
    );
    final payload = _decodeMap(response.body);
    final rawMessages = payload['messages'];
    if (rawMessages is! List) return const <SupportMessage>[];
    return rawMessages
        .whereType<Map>()
        .map((item) => SupportMessage.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Object? body,
    bool allowNotFound = false,
  }) async {
    final base = AppConfig.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const SupportTicketException(
          'Backend non configuré (API_BASE_URL vide).');
    }
    final token = await FirebaseAuthService.instance.currentIdToken(
      forceRefresh: method != 'GET',
    );
    if (token == null || token.isEmpty) {
      throw const SupportTicketException(
          'Session Firebase manquante, reconnectez-vous.');
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
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 12));
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 12));
          break;
        default:
          throw SupportTicketException('Méthode HTTP non supportée: $method');
      }
    } catch (error) {
      throw SupportTicketException(
          'Service assistance indisponible: ${error.toString()}');
    }

    if (allowNotFound && response.statusCode == 404) return response;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SupportTicketException(
          'Session expirée ou accès refusé. Reconnectez-vous.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SupportTicketException(_readErrorMessage(response.body));
    }
    return response;
  }

  Map<String, dynamic> _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const <String, dynamic>{};
  }

  String _readErrorMessage(String body) {
    final payload = _decodeMap(body);
    final message = _readString(payload['message']);
    if (message.isNotEmpty) return message;
    return 'Service assistance indisponible. Réessayez dans un instant.';
  }

  String _readString(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  User? get _currentFirebaseUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }
}
