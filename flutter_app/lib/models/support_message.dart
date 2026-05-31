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

class SupportMessage {
  const SupportMessage({
    required this.messageId,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    required this.isInternal,
    required this.readBySuperAdmin,
    required this.readByAdmin,
  });

  final String messageId;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String senderRole;
  final String message;
  final String createdAt;
  final bool isInternal;
  final bool readBySuperAdmin;
  final bool readByAdmin;

  bool get isSystem => senderRole == 'system';

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'ticketId': ticketId,
        'senderId': senderId,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'senderRole': senderRole,
        'message': message,
        'createdAt': createdAt,
        'isInternal': isInternal,
        'readBySuperAdmin': readBySuperAdmin,
        'readByAdmin': readByAdmin,
      };

  static SupportMessage fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SupportMessage(
      messageId: data['messageId'] as String? ?? doc.id,
      ticketId: data['ticketId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderEmail: data['senderEmail'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? 'system',
      message: data['message'] as String? ?? '',
      createdAt: _readDateString(data['createdAt']),
      isInternal: data['isInternal'] as bool? ?? true,
      readBySuperAdmin: data['readBySuperAdmin'] as bool? ?? false,
      readByAdmin: data['readByAdmin'] as bool? ?? false,
    );
  }
}
