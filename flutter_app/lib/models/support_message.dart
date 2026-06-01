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
    return _fromMap(data, fallbackId: doc.id);
  }

  static SupportMessage fromJson(Map<String, dynamic> json) {
    return _fromMap(json);
  }

  static SupportMessage _fromMap(
    Map<String, dynamic> data, {
    String fallbackId = '',
  }) {
    return SupportMessage(
      messageId: _readString(data['messageId'], fallbackId),
      ticketId: _readString(data['ticketId']),
      senderId: _readString(data['senderId']),
      senderName: _readString(data['senderName']),
      senderEmail: _readString(data['senderEmail']),
      senderRole: _readString(data['senderRole'], 'system'),
      message: _readString(data['message']),
      createdAt: _readDateString(data['createdAt']),
      isInternal: data['isInternal'] as bool? ?? true,
      readBySuperAdmin: data['readBySuperAdmin'] as bool? ?? false,
      readByAdmin: data['readByAdmin'] as bool? ?? false,
    );
  }
}
