import 'package:flutter/material.dart';

import '../services/citizen_access_code_service.dart';

class DuplicateRequestListPage extends StatefulWidget {
  const DuplicateRequestListPage({super.key});

  @override
  State<DuplicateRequestListPage> createState() => _DuplicateRequestListPageState();
}

class _DuplicateRequestListPageState extends State<DuplicateRequestListPage> {
  bool _isLoading = true;
  String _statusFilter = 'pending';
  List<DuplicateCodeRequestModel> _requests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final requests = await CitizenAccessCodeService.instance.getDuplicateRequestsForSuperAdmin(
      status: _statusFilter,
    );
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doublons a verifier')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in const ['pending', 'approved', 'rejected', 'all'])
                      ChoiceChip(
                        label: Text(status),
                        selected: _statusFilter == status,
                        onSelected: (_) {
                          setState(() => _statusFilter = status);
                          _load();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else if (_requests.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Aucune demande de doublon.')))
                else
                  for (final request in _requests)
                    _DuplicateRequestCard(
                      request: request,
                      onOpen: () async {
                        await Navigator.of(context).pushNamed('/super/duplicates/${request.id}');
                        _load();
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DuplicateRequestCard extends StatelessWidget {
  const _DuplicateRequestCard({required this.request, required this.onOpen});

  final DuplicateCodeRequestModel request;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.content_copy_rounded),
        title: Text('${request.communeName} · ${request.sourceKeyMasked}'),
        subtitle: Text(
          'Controleur: ${request.requestedByControllerName}\n'
          'Date: ${request.requestedAt}\n'
          'Code existant: ${request.existingAccessCode}\n'
          'Motif: ${request.duplicateReason.label}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(label: Text(request.status)),
            TextButton(onPressed: onOpen, child: const Text('Ouvrir')),
          ],
        ),
        titleTextStyle: theme.textTheme.titleMedium,
      ),
    );
  }
}