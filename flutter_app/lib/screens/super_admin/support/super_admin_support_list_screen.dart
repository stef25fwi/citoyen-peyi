import 'package:flutter/material.dart';

import '../../../models/support_ticket.dart';
import '../../../services/support_ticket_service.dart';
import '../../../widgets/support/ticket_card.dart';

class SuperAdminSupportListScreen extends StatefulWidget {
  const SuperAdminSupportListScreen({super.key});

  @override
  State<SuperAdminSupportListScreen> createState() =>
      _SuperAdminSupportListScreenState();
}

class _SuperAdminSupportListScreenState
    extends State<SuperAdminSupportListScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Tickets assistance'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: StreamBuilder<List<SupportTicket>>(
            stream:
                SupportTicketService.instance.watchAllTicketsForSuperAdmin(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
                  children: const [
                    _IntroCard(),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Impossible de charger les tickets d’assistance pour le moment.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              final tickets =
                  _applyFilters(snapshot.data ?? const <SupportTicket>[]);
              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
                children: [
                  const _IntroCard(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      labelText:
                          'Recherche par commune, sujet, catégorie ou email admin',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in const <String, String>{
                        'all': 'Tous',
                        'ouvert': 'Ouverts',
                        'en_cours': 'En cours',
                        'en_attente_admin': 'En attente admin',
                        'resolu': 'Résolus',
                        'ferme': 'Fermés',
                        'urgente': 'Urgents',
                        'unread': 'Non lus',
                      }.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _filter == entry.key,
                          onSelected: (_) =>
                              setState(() => _filter = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator()))
                  else if (tickets.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Aucun ticket d’assistance reçu pour le moment.',
                            textAlign: TextAlign.center),
                      ),
                    )
                  else
                    for (final ticket in tickets) ...[
                      TicketCard(
                        ticket: ticket,
                        showCommune: true,
                        showAdmin: true,
                        showUnreadForSuperAdmin: true,
                        onOpen: () => Navigator.of(context).pushNamed(
                            '/super-admin/support/${ticket.ticketId}'),
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

  List<SupportTicket> _applyFilters(List<SupportTicket> tickets) {
    final search = _searchCtrl.text.trim().toLowerCase();
    return tickets.where((ticket) {
      final filterOk = switch (_filter) {
        'all' => true,
        'urgente' => ticket.priority == 'urgente' && ticket.status != 'ferme',
        'unread' => ticket.unreadForSuperAdmin,
        _ => ticket.status == _filter,
      };
      if (!filterOk) return false;
      if (search.isEmpty) return true;
      return ticket.communeName.toLowerCase().contains(search) ||
          ticket.subject.toLowerCase().contains(search) ||
          ticket.category.toLowerCase().contains(search) ||
          ticket.createdByEmail.toLowerCase().contains(search);
    }).toList();
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

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
                  Text('Tickets assistance',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                      'Messages envoyés par les administrateurs communaux.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
