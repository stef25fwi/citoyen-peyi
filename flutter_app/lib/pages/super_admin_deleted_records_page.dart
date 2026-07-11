import 'package:flutter/material.dart';

import '../services/backup_admin_service.dart';

class SuperAdminDeletedRecordsPage extends StatefulWidget {
  const SuperAdminDeletedRecordsPage({super.key});

  @override
  State<SuperAdminDeletedRecordsPage> createState() => _SuperAdminDeletedRecordsPageState();
}

class _SuperAdminDeletedRecordsPageState extends State<SuperAdminDeletedRecordsPage> {
  bool _isLoading = true;
  String? _error;
  List<DeletedRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final records = await BackupAdminService.instance.listDeletedRecords();
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Historique des suppressions'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('File historique des données supprimées',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text(
                          'Les suppressions super admin sont retirées des listes actives, '
                          'mais un récapitulatif reste conservé ici et inclus dans les sauvegardes JSON.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Card(
                    color: const Color(0xFFFFEBEB),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
                    ),
                  )
                else if (_records.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Aucune suppression archivée pour le moment.')),
                    ),
                  )
                else
                  for (final record in _records) _DeletedRecordTile(record: record),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeletedRecordTile extends StatelessWidget {
  const _DeletedRecordTile({required this.record});

  final DeletedRecord record;

  @override
  Widget build(BuildContext context) {
    final kindLabel = switch (record.kind) {
      'commune_admin' => 'Admin communal',
      'consultation_agent' => 'Agent de consultation',
      _ => record.kind.isEmpty ? 'Donnée supprimée' : record.kind,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.history_rounded)),
        title: Text(record.displayTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('$kindLabel · ${formatCreatedAt(record.deletedAt)}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _InfoLine(label: 'Collection source', value: record.sourceCollection),
          _InfoLine(label: 'ID source', value: record.recordId),
          _InfoLine(label: 'Motif', value: record.reason),
          _InfoLine(label: 'Supprimé par', value: record.deletedBy),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Récapitulatif : ${record.data}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}

String formatCreatedAt(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso.isEmpty ? 'date inconnue' : iso;
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
