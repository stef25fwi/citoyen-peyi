import 'package:flutter/material.dart';

import '../../models/support_ticket.dart';
import 'ticket_priority_badge.dart';
import 'ticket_status_badge.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({
    required this.ticket,
    required this.onOpen,
    this.showCommune = false,
    this.showAdmin = false,
    this.showUnreadForAdmin = false,
    this.showUnreadForSuperAdmin = false,
    super.key,
  });

  final SupportTicket ticket;
  final VoidCallback onOpen;
  final bool showCommune;
  final bool showAdmin;
  final bool showUnreadForAdmin;
  final bool showUnreadForSuperAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = (showUnreadForAdmin && ticket.unreadForAdmin) ||
        (showUnreadForSuperAdmin && ticket.unreadForSuperAdmin);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showCommune && ticket.communeName.isNotEmpty) ...[
                          Text(
                            ticket.communeName,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF0D73F2),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          ticket.subject,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (showAdmin && ticket.createdByName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ticket.createdByEmail.isEmpty
                                ? ticket.createdByName
                                : '${ticket.createdByName} · ${ticket.createdByEmail}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (unread)
                    const Badge(
                      label: Text('Nouveau'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TicketStatusBadge(status: ticket.status),
                  TicketPriorityBadge(priority: ticket.priority),
                  Chip(label: Text(ticket.category)),
                  Chip(label: Text('${ticket.messagesCount} message(s)')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.lastMessage.isEmpty
                    ? 'Aucun message.'
                    : ticket.lastMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.updatedAt.isEmpty
                          ? 'Date indisponible'
                          : 'Dernière mise à jour : ${_formatDate(ticket.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Ouvrir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
