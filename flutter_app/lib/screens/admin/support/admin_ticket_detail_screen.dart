import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/support_message.dart';
import '../../../models/support_ticket.dart';
import '../../../services/support_ticket_service.dart';
import '../../../widgets/support/ticket_message_bubble.dart';
import '../../../widgets/support/ticket_priority_badge.dart';
import '../../../widgets/support/ticket_status_badge.dart';

class AdminTicketDetailScreen extends StatefulWidget {
  const AdminTicketDetailScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  State<AdminTicketDetailScreen> createState() => _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<AdminTicketDetailScreen> {
  final _messageCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    unawaited(SupportTicketService.instance.markTicketReadByAdmin(widget.ticketId));
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSending || _messageCtrl.text.trim().length < 2) return;
    setState(() => _isSending = true);
    try {
      await SupportTicketService.instance.sendMessage(
        ticketId: widget.ticketId,
        message: _messageCtrl.text,
      );
      _messageCtrl.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket assistance'), centerTitle: true),
      body: StreamBuilder<SupportTicket?>(
        stream: SupportTicketService.instance.watchTicket(widget.ticketId),
        builder: (context, ticketSnapshot) {
          final ticket = ticketSnapshot.data;
          if (ticketSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ticket == null) {
            return const Center(child: Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Ticket introuvable.'))));
          }
          return Column(
            children: [
              _TicketHeader(ticket: ticket),
              Expanded(
                child: StreamBuilder<List<SupportMessage>>(
                  stream: SupportTicketService.instance.watchTicketMessages(widget.ticketId),
                  builder: (context, messagesSnapshot) {
                    final messages = messagesSnapshot.data ?? const <SupportMessage>[];
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        for (final message in messages)
                          TicketMessageBubble(message: message, currentRole: 'admin_communal'),
                      ],
                    );
                  },
                ),
              ),
              _ReplyComposer(
                controller: _messageCtrl,
                isClosed: ticket.isClosed,
                isSending: _isSending,
                onSend: _send,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticket.subject, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              TicketStatusBadge(status: ticket.status),
              TicketPriorityBadge(priority: ticket.priority),
              Chip(label: Text(ticket.category)),
            ]),
            if (ticket.isClosed) ...[
              const SizedBox(height: 8),
              const Text('Ce ticket est fermé. Vous pouvez demander au super administrateur de le rouvrir si nécessaire.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.isClosed,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isClosed;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isClosed && !isSending,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isClosed ? 'Ticket fermé' : 'Écrire une réponse...',
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: isClosed || isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }
}
