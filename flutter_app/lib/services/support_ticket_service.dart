import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/support_message.dart';
import '../models/support_ticket.dart';
import 'auth_session_store.dart';
import 'firestore_data_service.dart';

class SupportTicketException implements Exception {
  const SupportTicketException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SupportTicketService {
  SupportTicketService._();

  static final SupportTicketService instance = SupportTicketService._();
  static const _collection = 'support_tickets';

  FirebaseFirestore get _db {
    final db = FirestoreDataService.instance;
    if (db == null) {
      throw const SupportTicketException(
        'Service assistance indisponible. Vérifiez la configuration Firebase.',
      );
    }
    return db;
  }

  CollectionReference<Map<String, dynamic>> get _tickets =>
      _db.collection(_collection);

  CollectionReference<Map<String, dynamic>>? get _maybeTickets =>
      FirestoreDataService.instance?.collection(_collection);

  Stream<T> _supportUnavailableStream<T>() {
    return Stream<T>.error(
      const SupportTicketException(
        'Service assistance indisponible. Vérifiez la configuration Firebase.',
      ),
    );
  }

  Stream<List<SupportTicket>> watchAdminTickets(String communeId) {
    if (communeId.trim().isEmpty) return Stream.value(const <SupportTicket>[]);
    final tickets = _maybeTickets;
    if (tickets == null) return _supportUnavailableStream<List<SupportTicket>>();
    return tickets
        .where('communeId', isEqualTo: communeId.trim())
        .snapshots()
        .map(_sortTickets);
  }

  Stream<List<SupportTicket>> watchAllTicketsForSuperAdmin() {
    final tickets = _maybeTickets;
    if (tickets == null) return _supportUnavailableStream<List<SupportTicket>>();
    return tickets.snapshots().map(_sortTickets);
  }

  Stream<List<SupportTicket>> watchUnreadTicketsForSuperAdmin() {
    final tickets = _maybeTickets;
    if (tickets == null) return _supportUnavailableStream<List<SupportTicket>>();
    return tickets
        .where('unreadForSuperAdmin', isEqualTo: true)
        .snapshots()
        .map(_sortTickets);
  }

  Stream<List<SupportTicket>> watchUnreadTicketsForAdmin(String communeId) {
    if (communeId.trim().isEmpty) return Stream.value(const <SupportTicket>[]);
    final tickets = _maybeTickets;
    if (tickets == null) return _supportUnavailableStream<List<SupportTicket>>();
    return tickets
        .where('communeId', isEqualTo: communeId.trim())
        .where('unreadForAdmin', isEqualTo: true)
        .snapshots()
        .map(_sortTickets);
  }

  Stream<SupportTicket?> watchTicket(String ticketId) {
    final tickets = _maybeTickets;
    if (tickets == null) return _supportUnavailableStream<SupportTicket?>();
    return tickets.doc(ticketId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SupportTicket.fromFirestore(doc);
    });
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
      throw const SupportTicketException('Le sujet doit contenir au moins 5 caractères.');
    }
    if (normalizedMessage.length < 10) {
      throw const SupportTicketException('Le message doit contenir au moins 10 caractères.');
    }
    if (!supportTicketCategories.contains(category)) {
      throw const SupportTicketException('Catégorie obligatoire.');
    }
    if (!supportTicketPriorities.contains(priority)) {
      throw const SupportTicketException('Priorité obligatoire.');
    }

    final session = AuthSessionStore.instance.currentSession;
    if (session?.isCommuneAdmin != true) {
      throw const SupportTicketException('Session administrateur communal requise.');
    }
    final communeId = (session?.commune?.code?.trim().isNotEmpty == true
            ? session!.commune!.code
            : session?.commune?.name)
        ?.trim();
    final communeName = session?.commune?.name.trim() ?? '';
    if (communeId == null || communeId.isEmpty || communeName.isEmpty) {
      throw const SupportTicketException('Commune rattachée introuvable.');
    }

    final user = FirebaseAuth.instance.currentUser;
    final ticketRef = _tickets.doc();
    final messageRef = ticketRef.collection('messages').doc();
    final senderId = user?.uid ?? session?.id ?? 'admin_communal';
    final senderName = session?.label ?? user?.displayName ?? 'Administrateur communal';
    final senderEmail = user?.email ?? '';
    final timestamp = FieldValue.serverTimestamp();

    final ticket = <String, dynamic>{
      'ticketId': ticketRef.id,
      'communeId': communeId,
      'communeName': communeName,
      'createdByUserId': senderId,
      'createdByName': senderName,
      'createdByEmail': senderEmail,
      'createdByRole': 'admin_communal',
      'assignedToRole': 'super_admin',
      'subject': normalizedSubject,
      'category': category,
      'priority': priority,
      'status': 'ouvert',
      'lastMessage': normalizedMessage,
      'lastMessageByRole': 'admin_communal',
      'messagesCount': 1,
      'unreadForSuperAdmin': true,
      'unreadForAdmin': false,
      'createdAt': timestamp,
      'updatedAt': timestamp,
      'closedAt': null,
      'closedBy': null,
    };
    final firstMessage = _messagePayload(
      messageId: messageRef.id,
      ticketId: ticketRef.id,
      senderId: senderId,
      senderName: senderName,
      senderEmail: senderEmail,
      senderRole: 'admin_communal',
      message: normalizedMessage,
      readBySuperAdmin: false,
      readByAdmin: true,
      timestamp: timestamp,
    );

    final batch = _db.batch();
    batch.set(ticketRef, ticket);
    batch.set(messageRef, firstMessage);
    await batch.commit();
    return ticketRef.id;
  }

  Stream<List<SupportMessage>> watchTicketMessages(String ticketId) {
    final tickets = _maybeTickets;
    if (tickets == null) return _supportUnavailableStream<List<SupportMessage>>();
    return tickets
        .doc(ticketId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(SupportMessage.fromFirestore)
            .toList(growable: false));
  }

  Future<void> sendMessage({
    required String ticketId,
    required String message,
  }) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.length < 2) {
      throw const SupportTicketException('Le message doit contenir au moins 2 caractères.');
    }
    final session = AuthSessionStore.instance.currentSession;
    final isSuperAdmin = session?.isSuperAdmin == true;
    final isAdmin = session?.isCommuneAdmin == true;
    if (!isSuperAdmin && !isAdmin) {
      throw const SupportTicketException('Session authentifiée requise.');
    }
    final role = isSuperAdmin ? 'super_admin' : 'admin_communal';
    final user = FirebaseAuth.instance.currentUser;
    final senderId = user?.uid ?? session?.id ?? role;
    final senderName = session?.label ?? user?.displayName ?? (isSuperAdmin ? 'Super administrateur' : 'Administrateur communal');
    final senderEmail = user?.email ?? '';
    final ticketRef = _tickets.doc(ticketId);
    final messageRef = ticketRef.collection('messages').doc();

    await _db.runTransaction((transaction) async {
      final ticket = await transaction.get(ticketRef);
      if (!ticket.exists) {
        throw const SupportTicketException('Ticket introuvable.');
      }
      final data = ticket.data() ?? const <String, dynamic>{};
      final status = data['status'] as String? ?? 'ouvert';
      if (status == 'ferme') {
        throw const SupportTicketException('Ce ticket est fermé. Rouvrez-le avant de répondre.');
      }
      final timestamp = FieldValue.serverTimestamp();
      final movesToInProgress = isSuperAdmin && status == 'ouvert';
      final systemMessageRef = movesToInProgress
          ? ticketRef.collection('messages').doc()
          : null;
      transaction.set(
        messageRef,
        _messagePayload(
          messageId: messageRef.id,
          ticketId: ticketId,
          senderId: senderId,
          senderName: senderName,
          senderEmail: senderEmail,
          senderRole: role,
          message: normalizedMessage,
          readBySuperAdmin: isSuperAdmin,
          readByAdmin: isAdmin,
          timestamp: timestamp,
        ),
      );
      if (systemMessageRef != null) {
        transaction.set(
          systemMessageRef,
          _messagePayload(
            messageId: systemMessageRef.id,
            ticketId: ticketId,
            senderId: senderId,
            senderName: 'Système',
            senderEmail: '',
            senderRole: 'system',
            message: 'Le ticket est passé au statut : En cours.',
            readBySuperAdmin: true,
            readByAdmin: false,
            timestamp: timestamp,
          ),
        );
      }
      transaction.update(ticketRef, {
        'lastMessage': normalizedMessage,
        'lastMessageByRole': role,
        'messagesCount': FieldValue.increment(movesToInProgress ? 2 : 1),
        'updatedAt': timestamp,
        'unreadForSuperAdmin': isAdmin,
        'unreadForAdmin': isSuperAdmin,
        if (movesToInProgress) 'status': 'en_cours',
      });
    });
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
    await _writeStatusChange(ticketId: ticketId, status: status);
  }

  Future<void> markTicketReadByAdmin(String ticketId) async {
    await _tickets.doc(ticketId).update({'unreadForAdmin': false});
  }

  Future<void> markTicketReadBySuperAdmin(String ticketId) async {
    await _tickets.doc(ticketId).update({'unreadForSuperAdmin': false});
  }

  Future<void> closeTicket(String ticketId) {
    return updateTicketStatus(ticketId: ticketId, status: 'ferme');
  }

  Future<void> reopenTicket(String ticketId) {
    return updateTicketStatus(ticketId: ticketId, status: 'en_cours');
  }

  Future<void> _writeStatusChange({
    required String ticketId,
    required String status,
  }) async {
    final session = AuthSessionStore.instance.currentSession;
    final user = FirebaseAuth.instance.currentUser;
    final senderId = user?.uid ?? session?.id ?? 'super_admin';
    final message = switch (status) {
      'en_cours' => 'Le ticket est passé au statut : En cours.',
      'en_attente_admin' => 'Le ticket est passé au statut : En attente admin.',
      'resolu' => 'Le ticket est passé au statut : Résolu.',
      'ferme' => 'Le ticket a été clôturé par le super administrateur.',
      'ouvert' => 'Le ticket a été rouvert.',
      _ => 'Le statut du ticket a été mis à jour.',
    };
    final ticketRef = _tickets.doc(ticketId);
    final messageRef = ticketRef.collection('messages').doc();
    await _db.runTransaction((transaction) async {
      final timestamp = FieldValue.serverTimestamp();
      transaction.set(
        messageRef,
        _messagePayload(
          messageId: messageRef.id,
          ticketId: ticketId,
          senderId: senderId,
          senderName: 'Système',
          senderEmail: '',
          senderRole: 'system',
          message: message,
          readBySuperAdmin: true,
          readByAdmin: false,
          timestamp: timestamp,
        ),
      );
      transaction.update(ticketRef, {
        'status': status,
        'lastMessage': message,
        'lastMessageByRole': 'system',
        'messagesCount': FieldValue.increment(1),
        'updatedAt': timestamp,
        'unreadForSuperAdmin': false,
        'unreadForAdmin': true,
        'closedAt': status == 'ferme' ? timestamp : null,
        'closedBy': status == 'ferme' ? senderId : null,
      });
    });
  }

  List<SupportTicket> _sortTickets(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final tickets = snapshot.docs.map(SupportTicket.fromFirestore).toList();
    tickets.sort((left, right) {
      final urgent = (right.isUrgent ? 1 : 0).compareTo(left.isUrgent ? 1 : 0);
      if (urgent != 0) return urgent;
      return right.updatedAt.compareTo(left.updatedAt);
    });
    return tickets;
  }

  Map<String, dynamic> _messagePayload({
    required String messageId,
    required String ticketId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String senderRole,
    required String message,
    required bool readBySuperAdmin,
    required bool readByAdmin,
    required Object timestamp,
  }) {
    return {
      'messageId': messageId,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderRole': senderRole,
      'message': message,
      'createdAt': timestamp,
      'isInternal': true,
      'readBySuperAdmin': readBySuperAdmin,
      'readByAdmin': readByAdmin,
    };
  }
}
