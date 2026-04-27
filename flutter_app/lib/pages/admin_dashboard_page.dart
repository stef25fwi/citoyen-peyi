import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/poll_models.dart';
import '../services/admin_analytics_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_session_store.dart';
import '../services/controleur_profile_service.dart';

class _DashboardTheme {
  static const background = Color(0xFFF6F7F9);
  static const foreground = Color(0xFF0F172A);
  static const mutedForeground = Color(0xFF64748B);
  static const border = Color(0xFFE5E7EB);
  static const primary = Color(0xFF0D73F2);
  static const accent = Color(0xFF20B69C);
  static const success = Color(0xFF2BA66A);
  static const warning = Color(0xFFF59E0B);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D73F2), Color(0xFF4F70F5)],
  );
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  List<PollModel> _polls = const [];
  List<ControleurProfileModel> _controleurs = const [];
  AdminAnalyticsSummary _analytics = const AdminAnalyticsSummary.empty();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      AdminAnalyticsService.instance.loadSummary(),
      ControleurProfileService.instance.loadProfiles(),
    ]);

    if (!mounted) return;

    final analytics = results[0] as AdminAnalyticsSummary;

    setState(() {
      _analytics = analytics;
      _polls = analytics.polls;
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

    final activeCount = _polls.where((poll) => poll.status == 'active').length;
    final closedCount = _polls.where((poll) => poll.status == 'closed').length;
    final draftCount = _polls.where((poll) => poll.status == 'draft').length;

    return Scaffold(
      backgroundColor: _DashboardTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/'),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_rounded, color: _DashboardTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('Tableau de bord'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/admin/create'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nouveau sondage'),
            ),
          ),
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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DashboardStatCard(
                    label: 'Total sondages',
                    value: '${_polls.length}',
                    icon: Icons.how_to_vote_rounded,
                    color: _DashboardTheme.primary,
                  ),
                  _DashboardStatCard(
                    label: 'En cours',
                    value: '$activeCount',
                    icon: Icons.bar_chart_rounded,
                    color: _DashboardTheme.success,
                  ),
                  _DashboardStatCard(
                    label: 'Termines',
                    value: '$closedCount',
                    icon: Icons.dashboard_rounded,
                    color: _DashboardTheme.accent,
                  ),
                  _DashboardStatCard(
                    label: 'Brouillons',
                    value: '$draftCount',
                    icon: Icons.edit_document,
                    color: _DashboardTheme.warning,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session administrateur', style: theme.textTheme.titleLarge),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Vue analytics', style: theme.textTheme.titleLarge),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed('/admin/analytics'),
                            child: const Text('Voir le detail'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AnalyticsMetricCard(
                            label: 'Votes emis',
                            value: '${_analytics.totalVotes}',
                            subtitle: 'sur ${_analytics.totalVoters} inscrits',
                          ),
                          _AnalyticsMetricCard(
                            label: 'Participation moyenne',
                            value: '${_analytics.averageParticipation.round()}%',
                            subtitle: '${_analytics.activeCount} actifs, ${_analytics.closedCount} clos',
                          ),
                          _AnalyticsMetricCard(
                            label: 'Codes actives',
                            value: '${_analytics.totalActivatedCodes}',
                            subtitle: 'sur ${_analytics.totalValidatedCodes} valides',
                          ),
                          _AnalyticsMetricCard(
                            label: 'Votes traces',
                            value: '${_analytics.totalUsedCodes}',
                            subtitle: 'sur les 7 derniers jours et sondages charges',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_isLoading && _analytics.polls.isEmpty)
                        Text(
                          'Aucune donnee analytics disponible pour le moment.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A6573)),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            final maxDailyVotes = _analytics.dailyVotes.fold<int>(
                              0,
                              (maxValue, item) => item.votes > maxValue ? item.votes : maxValue,
                            );
                            final trend = Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFD7E0EA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Votes sur 7 jours', style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 14),
                                  for (final daily in _analytics.dailyVotes)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _CompactDailyVotesRow(
                                        daily: daily,
                                        maxVotes: maxDailyVotes,
                                      ),
                                    ),
                                ],
                              ),
                            );
                            final participation = Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFD7E0EA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Participation par sondage', style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 14),
                                  for (final poll in _analytics.polls.take(3))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: _CompactPollParticipationRow(poll: poll),
                                    ),
                                ],
                              ),
                            );

                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: trend),
                                  const SizedBox(width: 16),
                                  Expanded(child: participation),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [trend, const SizedBox(height: 16), participation],
                            );
                          },
                        ),
                    ],
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Sondages récents', style: Theme.of(context).textTheme.titleLarge),
                          ),
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

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 640 ? (width - 52) / 2 : 210.0;

    return SizedBox(
      width: cardWidth.clamp(150.0, 220.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26)),
                    Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _DashboardTheme.mutedForeground)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  const _AnalyticsMetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - 88;
    final cardWidth = availableWidth < 240 ? availableWidth : 195.0;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD7E0EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CompactDailyVotesRow extends StatelessWidget {
  const _CompactDailyVotesRow({
    required this.daily,
    required this.maxVotes,
  });

  final DailyVotesMetric daily;
  final int maxVotes;

  @override
  Widget build(BuildContext context) {
    final scale = maxVotes <= 0 ? 1.0 : maxVotes.toDouble();

    return Row(
      children: [
        SizedBox(width: 38, child: Text(daily.label)),
        Expanded(
          child: LinearProgressIndicator(
            value: (daily.votes / scale).clamp(0, 1),
          ),
        ),
        const SizedBox(width: 12),
        Text('${daily.votes}'),
      ],
    );
  }
}

class _CompactPollParticipationRow extends StatelessWidget {
  const _CompactPollParticipationRow({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final rate = poll.totalVoters == 0 ? 0.0 : poll.totalVoted / poll.totalVoters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(poll.projectTitle, style: Theme.of(context).textTheme.titleSmall)),
            Text('${(rate * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: rate),
        const SizedBox(height: 6),
        Text('${poll.totalVoted}/${poll.totalVoters} votants'),
      ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DashboardTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _DashboardTheme.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.key_rounded, size: 18, color: _DashboardTheme.accent),
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
                      ?.copyWith(color: _DashboardTheme.mutedForeground),
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
                              color: _DashboardTheme.foreground,
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
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 13),
                            SizedBox(width: 4),
                            Text('Utilise', style: TextStyle(fontSize: 11)),
                          ],
                        ),
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
