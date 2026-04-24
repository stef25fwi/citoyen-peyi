import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_session_store.dart';
import '../services/firebase_auth_service.dart';
import '../services/super_admin_service.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  List<AdminProfileModel> _profiles = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final profiles = await SuperAdminService.instance.loadProfiles();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _isLoading = false;
    });
  }

  Future<void> _deleteProfile(AdminProfileModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce profil ?'),
        content: Text('Le profil "${profile.label}" et sa cle de connexion seront supprimes definitivement.'),
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
    if (confirmed != true) return;
    await SuperAdminService.instance.deleteProfile(profile.id);
    await _loadProfiles();
  }

  void _openCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => _CreateProfileDialog(
        onCreated: (profile) {
          _loadProfiles();
          _showKeyRevealDialog(profile);
        },
      ),
    );
  }

  void _showKeyRevealDialog(AdminProfileModel profile) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF2B9F82), size: 40),
        title: const Text('Profil cree avec succes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transmettez cette cle a l\'administrateur de "${profile.communeName}". Elle ne sera plus visible en clair apres fermeture.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8B4FE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      profile.accessKey,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: 1.2,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF6B21A8)),
                    tooltip: 'Copier la cle',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.accessKey));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cle copiee dans le presse-papiers.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AuthSessionStore.instance.currentSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Administration'),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: const Color(0xFF6B21A8)),
        leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6B21A8)),
        leadingWidth: 56,
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuthService.instance.signOut();
              await AuthSessionStore.instance.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text('Deconnexion'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6B21A8),
        foregroundColor: Colors.white,
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Creer un admin'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: _loadProfiles,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // Session card
                Card(
                  color: const Color(0xFFF3E8FF),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: Color(0xFF6B21A8), size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session?.label ?? 'Super Administrateur',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF6B21A8),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Role: ${session?.role ?? '-'}  •  Mode: ${session?.modeLabel ?? '-'}',
                                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7C3AED)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Profils administrateurs',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 12),
                    Chip(label: Text('${_profiles.length}')),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Chaque profil est rattache a une commune et possede une cle de connexion unique.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A6573)),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else if (_profiles.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          const Icon(Icons.group_outlined, size: 48, color: Color(0xFF9AA9B8)),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun profil administrateur cree.',
                            style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF5A6573)),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B21A8)),
                            onPressed: _openCreateDialog,
                            icon: const Icon(Icons.person_add_rounded),
                            label: const Text('Creer le premier profil'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final profile in _profiles) ...[
                    _ProfileCard(
                      profile: profile,
                      onDelete: () => _deleteProfile(profile),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Profile card ----------

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.profile, required this.onDelete});

  final AdminProfileModel profile;
  final VoidCallback onDelete;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _keyVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;

    final createdDate = () {
      try {
        return DateTime.parse(profile.createdAt).toLocal().toString().substring(0, 16);
      } catch (_) {
        return profile.createdAt;
      }
    }();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6D8F).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF0F6D8F)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.label,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${profile.communeName}${profile.codePostal != null ? " (${profile.codePostal})" : ""}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A6573)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: 'Supprimer',
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _keyVisible
                      ? SelectableText(
                          profile.accessKey,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 1.1,
                            color: Color(0xFF6B21A8),
                          ),
                        )
                      : Text(
                          '•' * profile.accessKey.length,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9AA9B8),
                            letterSpacing: 1,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_keyVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  tooltip: _keyVisible ? 'Masquer la cle' : 'Afficher la cle',
                  onPressed: () => setState(() => _keyVisible = !_keyVisible),
                ),
                if (_keyVisible)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: 'Copier la cle',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.accessKey));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cle copiee dans le presse-papiers.')),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cree le $createdDate',
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF9AA9B8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Create profile dialog ----------

class _CreateProfileDialog extends StatefulWidget {
  const _CreateProfileDialog({required this.onCreated});

  final void Function(AdminProfileModel) onCreated;

  @override
  State<_CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<_CreateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _communeCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _communeCtrl.dispose();
    _codeCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      final profile = await SuperAdminService.instance.createAdminProfile(
        label: _labelCtrl.text,
        communeName: _communeCtrl.text,
        communeCode: _codeCtrl.text.isEmpty ? null : _codeCtrl.text,
        codePostal: _postalCtrl.text.isEmpty ? null : _postalCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated(profile);
    } on SuperAdminAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add_rounded, color: Color(0xFF6B21A8)),
          SizedBox(width: 10),
          Text('Nouveau profil administrateur'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelCtrl,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Libelle du profil *',
                  hintText: 'Ex : Mairie de Baie-Mahault',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _communeCtrl,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Commune *',
                  hintText: 'Ex : Baie-Mahault',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postalCtrl,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Code postal',
                        hintText: '97122',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtrl,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Code INSEE',
                        hintText: '97109',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Une cle de connexion unique sera generee automatiquement.',
                style: TextStyle(color: Color(0xFF7A8796), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B21A8)),
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_isSubmitting ? 'Creation...' : 'Creer le profil'),
        ),
      ],
    );
  }
}
