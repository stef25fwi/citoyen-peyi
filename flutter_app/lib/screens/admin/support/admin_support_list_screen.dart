import 'package:flutter/material.dart';

import '../../../models/support_ticket.dart';
import '../../../services/auth_session_store.dart';
import '../../../services/support_ticket_service.dart';
import '../../../widgets/support/ticket_card.dart';

class AdminSupportListScreen extends StatelessWidget {
  const AdminSupportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionStore.instance.currentSession;
    final communeId = session?.commune?.code?.trim().isNotEmpty == true
        ? session!.commune!.code!.trim()
        : session?.commune?.name.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistance'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/admin/support/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau ticket'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: StreamBuilder<List<SupportTicket>>(
            stream: SupportTicketService.instance.watchAdminTickets(communeId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    _IntroCard(unreadCount: 0),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Impossible de charger les tickets pour le moment. Vérifiez votre connexion puis réessayez.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              final tickets = snapshot.data ?? const <SupportTicket>[];
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _IntroCard(unreadCount: tickets.where((item) => item.unreadForAdmin).length),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (tickets.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucun ticket pour le moment. Vous pouvez contacter le super administrateur en cas de besoin.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    for (final ticket in tickets) ...[
                      TicketCard(
                        ticket: ticket,
                        showUnreadForAdmin: true,
                        onOpen: () => Navigator.of(context).pushNamed('/admin/support/${ticket.ticketId}'),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: Color(0xFF0D73F2), size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assistance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Contactez le super administrateur en cas de problème, demande ou besoin d’accompagnement.'),
                ],
              ),
            ),
            if (unreadCount > 0) Badge(label: Text('$unreadCount')),
          ],
        ),
      ),
    );
  }
}
