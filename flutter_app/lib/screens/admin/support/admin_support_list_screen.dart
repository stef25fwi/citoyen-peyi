import 'package:flutter/material.dart';

import '../../../models/support_ticket.dart';
import '../../../services/auth_session_store.dart';
import '../../../services/support_ticket_service.dart';
import '../../../widgets/support/ticket_card.dart';

class AdminSupportListScreen extends StatefulWidget {
  const AdminSupportListScreen({super.key});

  @override
  State<AdminSupportListScreen> createState() => _AdminSupportListScreenState();
}

class _AdminSupportListScreenState extends State<AdminSupportListScreen> {
  int _reloadNonce = 0;

  void _retry() {
    setState(() => _reloadNonce++);
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionStore.instance.currentSession;
    final compactAppBar = MediaQuery.sizeOf(context).width < 600;
    final communeId = session?.commune?.code?.trim().isNotEmpty == true
        ? session!.commune!.code!.trim()
        : session?.commune?.name.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistance'),
        centerTitle: true,
        actions: [
          if (compactAppBar)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Nouveau ticket',
              onPressed: () =>
                  Navigator.of(context).pushNamed('/admin/support/new'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/admin/support/new'),
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
            key: ValueKey(_reloadNonce),
            stream: SupportTicketService.instance.watchAdminTickets(communeId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
                  children: [
                    const _IntroCard(unreadCount: 0),
                    const SizedBox(height: 16),
                    _SupportStateCard(
                      icon: Icons.cloud_off_rounded,
                      title:
                          'Impossible de charger les tickets pour le moment. Vérifiez votre connexion puis réessayez.',
                      action: OutlinedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
                      ),
                    ),
                  ],
                );
              }
              final tickets = snapshot.data ?? const <SupportTicket>[];
              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
                children: [
                  _IntroCard(
                      unreadCount:
                          tickets.where((item) => item.unreadForAdmin).length),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const _SupportStateCard(
                      icon: Icons.support_agent_rounded,
                      title: 'Chargement de l’assistance...',
                      showLoader: true,
                    )
                  else if (tickets.isEmpty)
                    const _SupportStateCard(
                      icon: Icons.mark_chat_unread_outlined,
                      title:
                          'Aucun ticket pour le moment. Vous pouvez contacter le super administrateur en cas de besoin.',
                    )
                  else
                    for (final ticket in tickets) ...[
                      TicketCard(
                        ticket: ticket,
                        showUnreadForAdmin: true,
                        onOpen: () => Navigator.of(context)
                            .pushNamed('/admin/support/${ticket.ticketId}'),
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

class _SupportStateCard extends StatelessWidget {
  const _SupportStateCard({
    required this.icon,
    required this.title,
    this.action,
    this.showLoader = false,
  });

  final IconData icon;
  final String title;
  final Widget? action;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLoader)
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Icon(icon, color: const Color(0xFF0D73F2), size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
        child: Row(
          children: [
            const Icon(Icons.support_agent_rounded,
                color: Color(0xFF0D73F2), size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assistance',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                      'Contactez le super administrateur en cas de problème, demande ou besoin d’accompagnement.'),
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
