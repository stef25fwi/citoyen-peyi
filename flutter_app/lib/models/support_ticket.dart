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
    return SupportTicket(
      ticketId: data['ticketId'] as String? ?? doc.id,
      communeId: data['communeId'] as String? ?? '',
      communeName: data['communeName'] as String? ?? '',
      createdByUserId: data['createdByUserId'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdByEmail: data['createdByEmail'] as String? ?? '',
      createdByRole: data['createdByRole'] as String? ?? 'admin_communal',
      assignedToRole: data['assignedToRole'] as String? ?? 'super_admin',
      subject: data['subject'] as String? ?? '',
      category: data['category'] as String? ?? '',
      priority: data['priority'] as String? ?? 'normale',
      status: data['status'] as String? ?? 'ouvert',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageByRole: data['lastMessageByRole'] as String? ?? '',
      messagesCount: (data['messagesCount'] as num?)?.toInt() ?? 0,
      unreadForSuperAdmin: data['unreadForSuperAdmin'] as bool? ?? false,
      unreadForAdmin: data['unreadForAdmin'] as bool? ?? false,
      createdAt: _readDateString(data['createdAt']),
      updatedAt: _readDateString(data['updatedAt']),
      closedAt: data['closedAt'] == null ? null : _readDateString(data['closedAt']),
      closedBy: data['closedBy'] as String?,
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
