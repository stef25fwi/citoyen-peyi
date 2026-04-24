import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
                          const SizedBox(height: 8),
                          Text(
                            'Utilisez le bouton + en bas a droite pour creer le premier profil.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF9AA9B8)),
                            textAlign: TextAlign.center,
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

// ---------- Commune suggestion model ----------

class _CommuneSuggestion {
  const _CommuneSuggestion({
    required this.nom,
    required this.code,
    required this.codesPostaux,
  });

  final String nom;
  final String code;
  final List<String> codesPostaux;

  String get firstPostal => codesPostaux.isNotEmpty ? codesPostaux.first : '';

  String get displayLabel =>
      codesPostaux.isEmpty ? nom : '$nom (${codesPostaux.join(', ')})';
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

  Timer? _debounce;
  List<_CommuneSuggestion> _suggestions = [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _labelCtrl.dispose();
    _communeCtrl.dispose();
    _codeCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<List<_CommuneSuggestion>> _fetchCommunes(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final isPostal = RegExp(r'^\d{2,5}$').hasMatch(q);
    final url = isPostal
        ? 'https://geo.api.gouv.fr/communes?codePostal=$q&fields=nom,code,codesPostaux,population&limit=10'
        : 'https://geo.api.gouv.fr/communes?nom=${Uri.encodeComponent(q)}&fields=nom,code,codesPostaux,population&boost=population&limit=10';

    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) {
        final m = e as Map<String, dynamic>;
        return _CommuneSuggestion(
          nom: m['nom'] as String? ?? '',
          code: m['code'] as String? ?? '',
          codesPostaux: (m['codesPostaux'] as List<dynamic>?)
                  ?.map((c) => c as String)
                  .toList() ??
              [],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void _onCommuneChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final results = await _fetchCommunes(value);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _searching = false;
        });
      }
    });
  }

  void _selectCommune(_CommuneSuggestion commune) {
    setState(() {
      _communeCtrl.text = commune.nom;
      _postalCtrl.text = commune.firstPostal;
      _codeCtrl.text = commune.code;
      _suggestions = [];
      // Pré-remplit le libellé si encore vide ou générique
      if (_labelCtrl.text.trim().isEmpty ||
          _labelCtrl.text.trim().toLowerCase().startsWith('mairie de ')) {
        _labelCtrl.text = 'Mairie de ${commune.nom}';
      }
    });
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
          Icon(Icons.person_add_rounded, color: Color(0xFF0F6D8F)),
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
              // ---------- Commune avec autocomplétion ----------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _communeCtrl,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Commune *',
                      hintText: 'Tapez le nom ou le code postal…',
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.location_on_outlined),
                    ),
                    onChanged: _onCommuneChanged,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD7E0EA)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = _suggestions[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_city_rounded,
                                size: 18, color: Color(0xFF0F6D8F)),
                            title: Text(c.nom,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${c.codesPostaux.join(', ')}  •  INSEE ${c.code}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => _selectCommune(c),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // ---------- Code postal + INSEE (auto-remplis, modifiables) ----------
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
                        prefixIcon: Icon(Icons.markunread_mailbox_outlined),
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
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ---------- Libellé (auto-rempli "Mairie de …", modifiable) ----------
              TextFormField(
                controller: _labelCtrl,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Libelle du profil *',
                  hintText: 'Ex : Mairie de Baie-Mahault',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
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
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F6D8F)),
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
