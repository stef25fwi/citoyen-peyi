import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/support_message.dart';
import '../../../models/support_ticket.dart';
import '../../../services/support_ticket_service.dart';
import '../../../widgets/support/ticket_message_bubble.dart';
import '../../../widgets/support/ticket_priority_badge.dart';
import '../../../widgets/support/ticket_status_badge.dart';

class SuperAdminTicketDetailScreen extends StatefulWidget {
  const SuperAdminTicketDetailScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  State<SuperAdminTicketDetailScreen> createState() => _SuperAdminTicketDetailScreenState();
}

class _SuperAdminTicketDetailScreenState extends State<SuperAdminTicketDetailScreen> {
  final _messageCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      SupportTicketService.instance.markTicketReadBySuperAdmin(widget.ticketId).catchError(
        (Object error, StackTrace stackTrace) {
          debugPrint('[SuperAdminTicketDetail] mark read failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        },
      ),
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSubmitting || _messageCtrl.text.trim().length < 2) return;
    setState(() => _isSubmitting = true);
    try {
      await SupportTicketService.instance.sendMessage(ticketId: widget.ticketId, message: _messageCtrl.text);
      _messageCtrl.clear();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _status(String status) async {
    setState(() => _isSubmitting = true);
    try {
      await SupportTicketService.instance.updateTicketStatus(ticketId: widget.ticketId, status: status);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail ticket assistance'), centerTitle: true),
      body: StreamBuilder<SupportTicket?>(
        stream: SupportTicketService.instance.watchTicket(widget.ticketId),
        builder: (context, ticketSnapshot) {
          final ticket = ticketSnapshot.data;
          if (ticketSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ticketSnapshot.hasError) {
            return const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Impossible de charger ce ticket pour le moment.'),
                ),
              ),
            );
          }
          if (ticket == null) {
            return const Center(child: Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Ticket introuvable.'))));
          }
          return Column(
            children: [
              _TicketHeader(ticket: ticket, isSubmitting: _isSubmitting, onStatus: _status),
              Expanded(
                child: StreamBuilder<List<SupportMessage>>(
                  stream: SupportTicketService.instance.watchTicketMessages(widget.ticketId),
                  builder: (context, messagesSnapshot) {
                    if (messagesSnapshot.hasError) {
                      return const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Impossible de charger les messages pour le moment.'),
                          ),
                        ),
                      );
                    }
                    if (messagesSnapshot.connectionState == ConnectionState.waiting && !messagesSnapshot.hasData) {
                      return const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Chargement des messages...'),
                          ),
                        ),
                      );
                    }
                    final messages = messagesSnapshot.data ?? const <SupportMessage>[];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Aucun message dans ce ticket pour le moment.'),
                          ),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        for (final message in messages)
                          TicketMessageBubble(message: message, currentRole: 'super_admin'),
                      ],
                    );
                  },
                ),
              ),
              _ReplyComposer(
                controller: _messageCtrl,
                isClosed: ticket.isClosed,
                isSubmitting: _isSubmitting,
                onSend: _send,
                onReopen: () => _status('en_cours'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket, required this.isSubmitting, required this.onStatus});

  final SupportTicket ticket;
  final bool isSubmitting;
  final ValueChanged<String> onStatus;

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
            const SizedBox(height: 4),
            Text('${ticket.communeName} · ${ticket.createdByName}${ticket.createdByEmail.isEmpty ? '' : ' · ${ticket.createdByEmail}'}'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              TicketStatusBadge(status: ticket.status),
              TicketPriorityBadge(priority: ticket.priority),
              Chip(label: Text(ticket.category)),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(onPressed: isSubmitting ? null : () => onStatus('en_cours'), child: const Text('En cours')),
                FilledButton.tonal(onPressed: isSubmitting ? null : () => onStatus('en_attente_admin'), child: const Text('En attente admin')),
                FilledButton.tonal(onPressed: isSubmitting ? null : () => onStatus('resolu'), child: const Text('Marquer comme résolu')),
                if (ticket.isClosed)
                  FilledButton(onPressed: isSubmitting ? null : () => onStatus('en_cours'), child: const Text('Rouvrir'))
                else
                  FilledButton(onPressed: isSubmitting ? null : () => onStatus('ferme'), child: const Text('Clôturer')),
              ],
            ),
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
    required this.isSubmitting,
    required this.onSend,
    required this.onReopen,
  });

  final TextEditingController controller;
  final bool isClosed;
  final bool isSubmitting;
  final VoidCallback onSend;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isClosed && !isSubmitting,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isClosed ? 'Ce ticket est fermé. Vous pouvez le rouvrir si nécessaire.' : 'Répondre à l’admin communal...',
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (isClosed)
              OutlinedButton.icon(onPressed: isSubmitting ? null : onReopen, icon: const Icon(Icons.lock_open_rounded), label: const Text('Rouvrir'))
            else
              FilledButton.icon(
                onPressed: isSubmitting ? null : onSend,
                icon: isSubmitting
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
