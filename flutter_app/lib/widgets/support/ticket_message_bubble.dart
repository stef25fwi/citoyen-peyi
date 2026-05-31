import 'package:flutter/material.dart';

import '../../models/support_message.dart';

class TicketMessageBubble extends StatelessWidget {
  const TicketMessageBubble({
    required this.message,
    required this.currentRole,
    super.key,
  });

  final SupportMessage message;
  final String currentRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              message.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    final isMine = message.senderRole == currentRole;
    final color = isMine ? const Color(0xFF0D73F2) : Colors.white;
    final foreground = isMine ? Colors.white : const Color(0xFF0F172A);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: isMine ? null : Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${message.senderName.isEmpty ? _roleLabel(message.senderRole) : message.senderName} · ${_roleLabel(message.senderRole)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(message.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foreground.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
        'super_admin' => 'Super admin',
        'admin_communal' => 'Admin communal',
        _ => role,
      };

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
