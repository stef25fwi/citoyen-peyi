import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/poll_models.dart';
import '../services/poll_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_session_store.dart';
import '../services/controleur_profile_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  List<PollModel> _polls = const [];
  List<ControleurProfileModel> _controleurs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      PollService.instance.loadPolls(),
      ControleurProfileService.instance.loadProfiles(),
    ]);

    if (!mounted) return;

    setState(() {
      _polls = results[0] as List<PollModel>;
      _controleurs = results[1] as List<ControleurProfileModel>;
      _isLoading = false;
    });
  }

  Future<void> _deleteControleur(ControleurProfileModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce controleur ?'),
        content: Text('Le code "${profile.code}" sera definitivement supprime.'),
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
    await ControleurProfileService.instance.deleteProfile(profile.code);
    await _load();
  }

  void _openCreateControleurDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => _CreateControleurDialog(
        onCreated: (profile) {
          _load();
          _showCodeRevealDialog(profile);
        },
      ),
    );
  }

  void _showCodeRevealDialog(ControleurProfileModel profile) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF2B9F82), size: 40),
        title: const Text('Controleur cree'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transmettez ce code a ${profile.label}. Il ne sera plus visible en clair apres fermeture.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7DD3FC)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      profile.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: 1.2,
                        color: Color(0xFF0F6D8F),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF0F6D8F)),
                    tooltip: 'Copier',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copie dans le presse-papiers.')),
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
        title: const Text('Tableau de bord admin'),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuthService.instance.signOut();
              await AuthSessionStore.instance.clear();
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text('Deconnexion'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session administrateur', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Text(
                        session == null
                            ? 'Aucune session chargee.'
                            : 'Role: ${session.role}\nScope: ${session.adminScope ?? 'global'}\nProfil: ${session.label ?? 'Administrateur'}\nMode: ${session.modeLabel}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final actions = [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pushNamed('/admin/create'),
                      child: const Text('Creer un sondage'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pushNamed('/admin/inscriptions'),
                      child: const Text('Inscriptions'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pushNamed('/admin/analytics'),
                      child: const Text('Analytics'),
                    ),
                  ];

                  if (wide) {
                    return Wrap(spacing: 12, runSpacing: 12, children: actions);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < actions.length; index++) ...[
                        actions[index],
                        if (index != actions.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Cette version Flutter utilise deja le backend d\'echange admin. Les pages metier restantes peuvent maintenant se brancher sur cette session.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ---------- Section Contrôleurs ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Controleurs', style: theme.textTheme.titleLarge),
                          ),
                          Chip(label: Text('${_controleurs.length}')),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _openCreateControleurDialog,
                            icon: const Icon(Icons.person_add_rounded, size: 18),
                            label: const Text('Nouveau'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_controleurs.isEmpty)
                        Text(
                          'Aucun controleur cree. Utilisez le bouton "Nouveau" pour en creer un.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF5A6573)),
                        )
                      else
                        for (final ctrl in _controleurs)
                          _ControleurRow(
                            profile: ctrl,
                            onDelete: () => _deleteControleur(ctrl),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ---------- Sondages récents ----------
              Card(
                          if (_isLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_isLoading && _polls.isEmpty)
                        const Text('Aucun sondage disponible pour le moment.')
                      else
                        for (final poll in _polls.take(5))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).pushNamed('/admin/poll/${poll.id}'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFD7E0EA)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(poll.projectTitle, style: theme.textTheme.titleMedium),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${poll.totalVoted}/${poll.totalVoters} votants · ${poll.status}',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
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

// ---------- Controleur row ----------

class _ControleurRow extends StatefulWidget {
  const _ControleurRow({required this.profile, required this.onDelete});

  final ControleurProfileModel profile;
  final VoidCallback onDelete;

  @override
  State<_ControleurRow> createState() => _ControleurRowState();
}

class _ControleurRowState extends State<_ControleurRow> {
  bool _codeVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E0EA)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0F6D8F).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.key_rounded, size: 18, color: Color(0xFF0F6D8F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.label,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${profile.communeName}${profile.codePostal != null ? " (${profile.codePostal})" : ""}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF5A6573)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _codeVisible
                        ? SelectableText(
                            profile.code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 1,
                              color: Color(0xFF0F6D8F),
                            ),
                          )
                        : Text(
                            '•' * profile.code.length,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF9AA9B8)),
                          ),
                    const SizedBox(width: 4),
                    if (profile.hasBeenUsed)
                      const Chip(
                        label: Text('Utilise',
                            style: TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
                _codeVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20),
            onPressed: () => setState(() => _codeVisible = !_codeVisible),
            tooltip: _codeVisible ? 'Masquer' : 'Afficher le code',
          ),
          if (_codeVisible)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: profile.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copie.')),
                );
              },
              tooltip: 'Copier',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Colors.red),
            onPressed: widget.onDelete,
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }
}

// ---------- Create controleur dialog ----------

class _CreateControleurDialog extends StatefulWidget {
  const _CreateControleurDialog({required this.onCreated});

  final void Function(ControleurProfileModel) onCreated;

  @override
  State<_CreateControleurDialog> createState() =>
      _CreateControleurDialogState();
}

class _CreateControleurDialogState extends State<_CreateControleurDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _communeCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _communeCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      final profile = await ControleurProfileService.instance.createProfile(
        label: _labelCtrl.text,
        communeName: _communeCtrl.text,
        codePostal: _postalCtrl.text.isEmpty ? null : _postalCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated(profile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
          Text('Nouveau controleur'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelCtrl,
                enabled: !_isSubmitting,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nom / libelle *',
                  hintText: 'Ex : Jean Dupont',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _communeCtrl,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Commune *',
                  hintText: 'Ex : Baie-Mahault',
                  prefixIcon: Icon(Icons.location_city_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _postalCtrl,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Code postal',
                  hintText: '97122',
                  prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Un code de connexion unique sera genere automatiquement.',
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
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_isSubmitting ? 'Creation...' : 'Creer le controleur'),
        ),
      ],
    );
  }
}
