import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backup_admin_service.dart';

class SuperAdminBackupPage extends StatefulWidget {
  const SuperAdminBackupPage({super.key});

  @override
  State<SuperAdminBackupPage> createState() => _SuperAdminBackupPageState();
}

class _SuperAdminBackupPageState extends State<SuperAdminBackupPage> {
  bool _isLoading = true;
  bool _isCreating = false;
  List<BackupSnapshot> _snapshots = const [];
  String? _error;

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
      final snapshots = await BackupAdminService.instance.listSnapshots();
      if (!mounted) return;
      setState(() {
        _snapshots = snapshots;
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

  Future<void> _createSnapshot() async {
    setState(() => _isCreating = true);
    try {
      final snapshot = await BackupAdminService.instance.createSnapshot();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Sauvegarde creee : ${snapshot.totalDocuments} documents.'),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _showDownloadUrl(BackupSnapshot snapshot) async {
    try {
      final url =
          await BackupAdminService.instance.signedDownloadUrl(snapshot.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Lien de telechargement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Lien signe valable 10 minutes. Conservez ce JSON hors-ligne pour une restauration ulterieure.'),
              const SizedBox(height: 12),
              SelectableText(url, style: const TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien copie.')),
                );
              },
              child: const Text('Copier'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteSnapshot(BackupSnapshot snapshot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette sauvegarde ?'),
        content:
            Text('Le snapshot ${snapshot.id} sera supprime definitivement.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BackupAdminService.instance.deleteSnapshot(snapshot.id);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openRestore(BackupSnapshot snapshot) async {
    final restored = await showDialog<bool>(
      context: context,
      builder: (_) => _RestoreDialog(snapshot: snapshot),
    );
    if (restored == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Sauvegardes & restauration'),
        actions: [
          IconButton(
            tooltip: 'Rafraichir',
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
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sauvegarde de la base',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        const Text(
                          'Cree un instantane JSON de toute la base (profils, agents, '
                          'codes citoyens, sondages et votes) dans le bucket prive. '
                          'Aucun secret n\'est inclus.',
                          style: TextStyle(color: Color(0xFF5A6573)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isCreating ? null : _createSnapshot,
                            icon: _isCreating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.cloud_upload_rounded),
                            label: Text(_isCreating
                                ? 'Sauvegarde en cours...'
                                : 'Creer une sauvegarde'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Sauvegardes disponibles',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
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
                      child: Text(_error!,
                          style: const TextStyle(color: Color(0xFFB42318))),
                    ),
                  )
                else if (_snapshots.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: Text('Aucune sauvegarde pour le moment.')),
                    ),
                  )
                else
                  ..._snapshots.map(
                    (snapshot) => _SnapshotTile(
                      snapshot: snapshot,
                      onRestore: () => _openRestore(snapshot),
                      onDownload: () => _showDownloadUrl(snapshot),
                      onDelete: () => _deleteSnapshot(snapshot),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 o';
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
}

String formatCreatedAt(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({
    required this.snapshot,
    required this.onRestore,
    required this.onDownload,
    required this.onDelete,
  });

  final BackupSnapshot snapshot;
  final VoidCallback onRestore;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.archive_outlined)),
        title: Text(formatCreatedAt(snapshot.createdAt),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${snapshot.totalDocuments} documents · ${formatBytes(snapshot.size)}\n${snapshot.id}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                onRestore();
                break;
              case 'download':
                onDownload();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'restore', child: Text('Restaurer')),
            PopupMenuItem(value: 'download', child: Text('Telecharger (lien)')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }
}

class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog({required this.snapshot});

  final BackupSnapshot snapshot;

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  String _mode = 'merge';
  bool _busy = false;
  RestoreReport? _preview;
  String? _error;

  Future<void> _run({required bool dryRun}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final report = await BackupAdminService.instance.restore(
        widget.snapshot.id,
        mode: _mode,
        dryRun: dryRun,
        force: _mode == 'mirror',
      );
      if (!mounted) return;
      if (dryRun) {
        setState(() {
          _preview = report;
          _busy = false;
        });
      } else {
        // Capturer le messenger avant de fermer le dialog (contexte detruit ensuite).
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context, true);
        messenger.showSnackBar(
          SnackBar(
            content:
                Text('Restauration ${report.mode} : ${report.writes} ecrits, '
                    '${report.deletes} supprimes, ${report.skipped} ignores.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _busy = false;
      });
    }
  }

  Future<void> _confirmApply() async {
    final isMirror = _mode == 'mirror';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isMirror
            ? 'Confirmer le mode miroir'
            : 'Confirmer la restauration'),
        content: Text(isMirror
            ? 'Le mode MIROIR supprimera les documents absents du snapshot. '
                'Action irreversible. Continuer ?'
            : 'Les documents du snapshot seront re-ecrits (les documents plus '
                'recents sont preserves). Continuer ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: isMirror ? Colors.red : null),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isMirror ? 'Supprimer & restaurer' : 'Restaurer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(dryRun: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return AlertDialog(
      title: const Text('Restaurer la sauvegarde'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.snapshot.id, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            const Text('Mode de restauration',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'merge',
                    label: Text('Fusion'),
                    icon: Icon(Icons.merge_rounded)),
                ButtonSegment(
                    value: 'mirror',
                    label: Text('Miroir'),
                    icon: Icon(Icons.compare_arrows_rounded)),
              ],
              selected: {_mode},
              onSelectionChanged: _busy
                  ? null
                  : (selection) => setState(() {
                        _mode = selection.first;
                        _preview = null;
                      }),
            ),
            const SizedBox(height: 6),
            Text(
              _mode == 'mirror'
                  ? 'Miroir : supprime les documents absents du snapshot (irreversible).'
                  : 'Fusion : re-ecrit les documents, ne supprime rien, preserve les plus recents.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5A6573)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
            ],
            if (preview != null) ...[
              const Divider(height: 24),
              Text(
                'Simulation : ${preview.writes} ecrits · '
                '${preview.deletes} supprimes · ${preview.skipped} ignores',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final c in preview.collections)
                        if (c.writes + c.deletes + c.skipped > 0)
                          Text(
                            '${c.collection} : +${c.writes} -${c.deletes} ~${c.skipped}',
                            style: const TextStyle(fontSize: 12),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Fermer'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _run(dryRun: true),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simuler'),
        ),
        FilledButton(
          onPressed: (_busy || preview == null) ? null : _confirmApply,
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}
