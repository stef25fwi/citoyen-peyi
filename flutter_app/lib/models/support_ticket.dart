import 'package:cloud_firestore/cloud_firestore.dart';

String _readDateString(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is DateTime) return value.toIso8601String();
  if (value is Timestamp) return value.toDate().toIso8601String();
  try {
    final dynamic dynamicValue = value;
    final dynamic date = dynamicValue.toDate();
    if (date is DateTime) return date.toIso8601String();
  } catch (_) {}
  return value.toString();
}

String _readString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

int _readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(_readString(value)) ?? 0;
}

class SupportTicket {
  const SupportTicket({
    required this.ticketId,
    required this.communeId,
    required this.communeName,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdByEmail,
    required this.createdByRole,
    required this.assignedToRole,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.lastMessage,
    required this.lastMessageByRole,
    required this.messagesCount,
    required this.unreadForSuperAdmin,
    required this.unreadForAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.closedBy,
  });

  final String ticketId;
  final String communeId;
  final String communeName;
  final String createdByUserId;
  final String createdByName;
  final String createdByEmail;
  final String createdByRole;
  final String assignedToRole;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final String lastMessage;
  final String lastMessageByRole;
  final int messagesCount;
  final bool unreadForSuperAdmin;
  final bool unreadForAdmin;
  final String createdAt;
  final String updatedAt;
  final String? closedAt;
  final String? closedBy;

  bool get isClosed => status == 'ferme';
  bool get isUrgent => priority == 'urgente';

  SupportTicket copyWith({
    String? status,
    String? lastMessage,
    String? lastMessageByRole,
    int? messagesCount,
    bool? unreadForSuperAdmin,
    bool? unreadForAdmin,
    String? updatedAt,
    String? closedAt,
    String? closedBy,
  }) {
    return SupportTicket(
      ticketId: ticketId,
      communeId: communeId,
      communeName: communeName,
      createdByUserId: createdByUserId,
      createdByName: createdByName,
      createdByEmail: createdByEmail,
      createdByRole: createdByRole,
      assignedToRole: assignedToRole,
      subject: subject,
      category: category,
      priority: priority,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageByRole: lastMessageByRole ?? this.lastMessageByRole,
      messagesCount: messagesCount ?? this.messagesCount,
      unreadForSuperAdmin: unreadForSuperAdmin ?? this.unreadForSuperAdmin,
      unreadForAdmin: unreadForAdmin ?? this.unreadForAdmin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      closedBy: closedBy ?? this.closedBy,
    );
  }

  Map<String, dynamic> toMap() => {
        'ticketId': ticketId,
        'communeId': communeId,
        'communeName': communeName,
        'createdByUserId': createdByUserId,
        'createdByName': createdByName,
        'createdByEmail': createdByEmail,
        'createdByRole': createdByRole,
        'assignedToRole': assignedToRole,
        'subject': subject,
        'category': category,
        'priority': priority,
        'status': status,
        'lastMessage': lastMessage,
        'lastMessageByRole': lastMessageByRole,
        'messagesCount': messagesCount,
        'unreadForSuperAdmin': unreadForSuperAdmin,
        'unreadForAdmin': unreadForAdmin,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'closedAt': closedAt,
        'closedBy': closedBy,
      };

  static SupportTicket fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return _fromMap(data, fallbackId: doc.id);
  }

  static SupportTicket fromJson(Map<String, dynamic> json) {
    return _fromMap(json);
  }

  static SupportTicket _fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return SupportTicket(
      ticketId: _readString(data['ticketId'], fallbackId),
      communeId: _readString(data['communeId']),
      communeName: _readString(data['communeName']),
      createdByUserId: _readString(data['createdByUserId']),
      createdByName: _readString(data['createdByName']),
      createdByEmail: _readString(data['createdByEmail']),
      createdByRole: _readString(data['createdByRole'], 'admin_communal'),
      assignedToRole: _readString(data['assignedToRole'], 'super_admin'),
      subject: _readString(data['subject']),
      category: _readString(data['category']),
      priority: _readString(data['priority'], 'normale'),
      status: _readString(data['status'], 'ouvert'),
      lastMessage: _readString(data['lastMessage']),
      lastMessageByRole: _readString(data['lastMessageByRole']),
      messagesCount: _readInt(data['messagesCount']),
      unreadForSuperAdmin: data['unreadForSuperAdmin'] as bool? ?? false,
      unreadForAdmin: data['unreadForAdmin'] as bool? ?? false,
      createdAt: _readDateString(data['createdAt']),
      updatedAt: _readDateString(data['updatedAt']),
      closedAt:
          data['closedAt'] == null ? null : _readDateString(data['closedAt']),
      closedBy: data['closedBy'] == null ? null : _readString(data['closedBy']),
    );
  }
}

const supportTicketCategories = <String>[
  'Problème de connexion',
  'Problème de consultation',
  'Problème de code citoyen',
  'Problème de vote',
  'Demande de modification',
  'Demande de formation',
  'Problème technique',
  'Autre',
];

const supportTicketPriorities = <String>['faible', 'normale', 'urgente'];
const supportTicketStatuses = <String>[
  'ouvert',
  'en_cours',
  'en_attente_admin',
  'resolu',
  'ferme',
];
