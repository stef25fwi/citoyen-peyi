import 'package:flutter/material.dart';

import '../services/super_admin_service.dart';

class SuperAdminAdminsPage extends StatefulWidget {
  const SuperAdminAdminsPage({super.key});

  @override
  State<SuperAdminAdminsPage> createState() => _SuperAdminAdminsPageState();
}

class _SuperAdminAdminsPageState extends State<SuperAdminAdminsPage> {
  bool _isLoading = true;
  bool _isBulkDeleting = false;
  String? _error;
  List<AdminProfileModel> _profiles = const [];
  final Set<String> _selectedIds = <String>{};

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
      final profiles = await SuperAdminService.instance.loadProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _selectedIds.removeWhere((id) => !profiles.any((profile) => profile.id == id));
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

  Future<void> _deleteProfile(AdminProfileModel profile) async {
    final confirmed = await _confirmDelete(1);
    if (confirmed != true) return;
    try {
      await SuperAdminService.instance.deleteProfile(profile.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil "${profile.label}" supprimé et archivé.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade700, content: Text(error.toString())),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList(growable: false);
    if (ids.isEmpty || _isBulkDeleting) return;
    final confirmed = await _confirmDelete(ids.length);
    if (confirmed != true) return;
    setState(() => _isBulkDeleting = true);
    try {
      await SuperAdminService.instance.bulkDeleteProfiles(ids);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ids.length} profil(s) supprimé(s) et archivé(s).')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade700, content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isBulkDeleting = false);
    }
  }

  Future<bool?> _confirmDelete(int count) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(count == 1 ? 'Supprimer ce profil ?' : 'Supprimer $count profils ?'),
        content: const Text(
          'Les profils seront retirés des listes actives et conservés dans l’historique des suppressions. '
          'Les statistiques actives ne doivent plus afficher les communes supprimées après rafraîchissement.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _toggleProfile(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _toggleAll(bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.addAll(_profiles.map((profile) => profile.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected = _profiles.isNotEmpty &&
        _profiles.every((profile) => _selectedIds.contains(profile.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Admins communaux'),
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
          constraints: const BoxConstraints(maxWidth: 1000),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Comptes administrateurs communaux', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  '${_profiles.length} profil(s) actif(s). Sélectionnez plusieurs lignes pour les supprimer en une seule action.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                if (_profiles.isNotEmpty)
                  _BulkSelectionBar(
                    selectedCount: _selectedIds.length,
                    allSelected: allSelected,
                    busy: _isBulkDeleting,
                    onToggleAll: _toggleAll,
                    onDeleteSelected: _deleteSelected,
                  ),
                if (_profiles.isNotEmpty) const SizedBox(height: 12),
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
                else if (_profiles.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Aucun profil administrateur actif.')),
                    ),
                  )
                else
                  for (final profile in _profiles)
                    _AdminProfileTile(
                      profile: profile,
                      selected: _selectedIds.contains(profile.id),
                      onSelectedChanged: (selected) => _toggleProfile(profile.id, selected),
                      onDelete: () => _deleteProfile(profile),
                    ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/super'),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Créer depuis le tableau de bord'),
      ),
    );
  }
}

class _BulkSelectionBar extends StatelessWidget {
  const _BulkSelectionBar({
    required this.selectedCount,
    required this.allSelected,
    required this.busy,
    required this.onToggleAll,
    required this.onDeleteSelected,
  });

  final int selectedCount;
  final bool allSelected;
  final bool busy;
  final ValueChanged<bool> onToggleAll;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(value: allSelected, onChanged: (v) => onToggleAll(v == true)),
                Text(selectedCount == 0
                    ? 'Sélection multiple'
                    : '$selectedCount élément(s) sélectionné(s)'),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: selectedCount == 0 || busy ? null : onDeleteSelected,
              icon: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_sweep_rounded),
              label: const Text('Supprimer la sélection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminProfileTile extends StatelessWidget {
  const _AdminProfileTile({
    required this.profile,
    required this.selected,
    required this.onSelectedChanged,
    required this.onDelete,
  });

  final AdminProfileModel profile;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: selected, onChanged: (v) => onSelectedChanged(v == true)),
            const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0F6D8F)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.communeName} · ${profile.communeCode ?? 'code INSEE absent'} · ${profile.codePostal ?? 'CP absent'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                  ),
                  if (profile.referenceEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(profile.referenceEmail, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Supprimer',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
