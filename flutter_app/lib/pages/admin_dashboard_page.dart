import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/poll_models.dart';
import '../models/support_ticket.dart';
import '../services/admin_analytics_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/auth_session_store.dart';
import '../services/controleur_profile_service.dart';
import '../services/support_ticket_service.dart';
import '../widgets/support/ticket_card.dart';

class _DashboardTheme {
  static const background = Color(0xFFF6F7F9);
  static const foreground = Color(0xFF0F172A);
  static const mutedForeground = Color(0xFF64748B);
  static const border = Color(0xFFE5E7EB);
  static const primary = Color(0xFF0D73F2);
  static const accent = Color(0xFF20B69C);
  static const success = Color(0xFF2BA66A);
  static const warning = Color(0xFFF59E0B);
}

enum AdminDashboardSection { overview, polls, controllers }

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    this.initialSection = AdminDashboardSection.overview,
    super.key,
  });

  final AdminDashboardSection initialSection;

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

    AdminAnalyticsSummary analytics = _analytics;
    List<ControleurProfileModel> controleurs = _controleurs;
    Object? loadError;

    try {
      analytics = await AdminAnalyticsService.instance.loadSummary();
    } catch (error, stackTrace) {
      loadError = error;
      debugPrint('[AdminDashboard] loadSummary failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      controleurs = await ControleurProfileService.instance.loadProfiles();
    } catch (error, stackTrace) {
      debugPrint('[AdminDashboard] loadProfiles failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;

    setState(() {
      _analytics = analytics;
      _polls = analytics.polls;
      _controleurs = controleurs;
      _isLoading = false;
    });

    if (loadError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Impossible de rafraichir le tableau de bord administrateur: '
            '${loadError.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteControleur(ControleurProfileModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cet agent de mobilisation citoyenne ?'),
        content:
            Text('Le profil "${profile.label}" sera désactivé immédiatement.'),
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
    await ControleurProfileService.instance.deleteProfile(profile.id);
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
        icon: const Icon(Icons.check_circle_rounded,
            color: Color(0xFF2B9F82), size: 40),
        title: const Text('Agent de mobilisation citoyenne créé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Copiez ce code maintenant pour ${profile.label}. Il ne sera plus visible en clair après fermeture.',
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
                    icon: const Icon(Icons.copy_rounded,
                        color: Color(0xFF0F6D8F)),
                    tooltip: 'Copier',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Code copié dans le presse-papiers.')),
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

  Future<void> _signOut() async {
    try {
      await FirebaseAuthService.instance.signOut();
    } catch (error, stackTrace) {
      debugPrint('[AdminDashboard] signOut failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    try {
      await AuthSessionStore.instance.clear();
    } catch (error, stackTrace) {
      debugPrint('[AdminDashboard] session clear failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactAppBar = MediaQuery.sizeOf(context).width < 960;
    final session = AuthSessionStore.instance.currentSession;
    final showOverviewSection =
        widget.initialSection == AdminDashboardSection.overview;
    final showPollsSection =
        widget.initialSection != AdminDashboardSection.controllers;
    final showControllersSection =
        widget.initialSection != AdminDashboardSection.polls;
    final pageTitle = switch (widget.initialSection) {
      AdminDashboardSection.overview => 'Tableau de bord commune',
      AdminDashboardSection.polls => 'Consultations communales',
      AdminDashboardSection.controllers => 'Agents de mobilisation citoyenne communaux',
    };

    final activeCount = _polls.where((poll) => poll.status == 'active').length;
    final closedCount = _polls.where((poll) => poll.status == 'closed').length;
    final archivedCount =
        _polls.where((poll) => poll.status == 'archived').length;
    final draftCount = _polls.where((poll) => poll.status == 'draft').length;

    return Scaffold(
      backgroundColor: _DashboardTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/'),
        ),
        title: compactAppBar
            ? const Text('Tableau de bord')
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dashboard_rounded,
                      color: _DashboardTheme.primary, size: 22),
                  SizedBox(width: 8),
                  Text('Tableau de bord commune'),
                ],
              ),
        actions: [
          if (compactAppBar)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Nouvelle consultation',
              onPressed: () =>
                  Navigator.of(context).pushNamed('/admin/polls/create'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/admin/polls/create'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nouvelle consultation'),
              ),
            ),
          compactAppBar
              ? IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Déconnexion',
                  onPressed: _signOut,
                )
              : TextButton(
                  onPressed: _signOut,
                  child: const Text('Déconnexion'),
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
                Row(
                  children: [
                    Icon(
                      widget.initialSection == AdminDashboardSection.controllers
                          ? Icons.groups_rounded
                          : widget.initialSection == AdminDashboardSection.polls
                              ? Icons.how_to_vote_rounded
                              : Icons.dashboard_rounded,
                      color: _DashboardTheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(pageTitle,
                            style: theme.textTheme.headlineSmall)),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Vue d\'ensemble'),
                      selected: widget.initialSection ==
                          AdminDashboardSection.overview,
                      onSelected: (_) =>
                          Navigator.of(context).pushNamed('/admin'),
                    ),
                    ChoiceChip(
                      label: const Text('Consultations'),
                      selected:
                          widget.initialSection == AdminDashboardSection.polls,
                      onSelected: (_) =>
                          Navigator.of(context).pushNamed('/admin/polls'),
                    ),
                    ChoiceChip(
                      label: const Text('Agents de mobilisation citoyenne'),
                      selected: widget.initialSection ==
                          AdminDashboardSection.controllers,
                      onSelected: (_) =>
                          Navigator.of(context).pushNamed('/admin/controllers'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (showOverviewSection)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _DashboardStatCard(
                        label: 'Total consultations',
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
                        label: 'Terminées',
                        value: '$closedCount',
                        icon: Icons.dashboard_rounded,
                        color: _DashboardTheme.accent,
                      ),
                      _DashboardStatCard(
                        label: 'Archivées',
                        value: '$archivedCount',
                        icon: Icons.archive_rounded,
                        color: const Color(0xFF64748B),
                      ),
                      _DashboardStatCard(
                        label: 'Brouillons',
                        value: '$draftCount',
                        icon: Icons.edit_document,
                        color: _DashboardTheme.warning,
                      ),
                    ],
                  ),
                if (showOverviewSection) const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Session admin communal',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Text(
                          session == null
                              ? 'Aucune session chargée.'
                              : 'Role UX: commune_admin\nRole technique: ${session.role}\nCommune: ${session.commune?.name ?? 'mode global/fallback'}\nProfil: ${session.label ?? 'Administrateur communal'}\nMode: ${session.modeLabel}',
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
                        onPressed: () => Navigator.of(context)
                            .pushNamed('/admin/polls/create'),
                        child: const Text('Créer une consultation'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context)
                            .pushNamed('/admin/controllers'),
                        child: const Text('Agents de mobilisation citoyenne'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/admin/settings'),
                        child: const Text('Paramètres'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/admin/results'),
                        child: const Text('Resultats'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/admin/support'),
                        child: const Text('Assistance'),
                      ),
                    ];

                    if (wide) {
                      return Wrap(
                          spacing: 12, runSpacing: 12, children: actions);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var index = 0;
                            index < actions.length;
                            index++) ...[
                          actions[index],
                          if (index != actions.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (showOverviewSection)
                  _AdminSupportDashboardSection(
                    communeId: session?.commune?.code?.trim().isNotEmpty == true
                        ? session!.commune!.code!.trim()
                        : session?.commune?.name.trim() ?? '',
                  onCreateTicket: () =>
                    Navigator.of(context).pushNamed('/admin/support/new'),
                  onOpenTickets: () =>
                    Navigator.of(context).pushNamed('/admin/support'),
                  onOpenTicket: (ticket) => Navigator.of(context)
                    .pushNamed('/admin/support/${ticket.ticketId}'),
                  onRetry: _load,
                  ),
                if (showOverviewSection) const SizedBox(height: 16),
                if (showOverviewSection)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Vue analytics',
                                    style: theme.textTheme.titleLarge),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed('/admin/results'),
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
                                subtitle:
                                    'sur ${_analytics.totalVoters} inscrits',
                              ),
                              _AnalyticsMetricCard(
                                label: 'Participation moyenne',
                                value:
                                    '${_analytics.averageParticipation.round()}%',
                                subtitle:
                                    '${_analytics.activeCount} actifs, ${_analytics.completedCount} termines',
                              ),
                              _AnalyticsMetricCard(
                                label: 'Codes actives',
                                value: '${_analytics.totalActivatedCodes}',
                                subtitle:
                                    'sur ${_analytics.totalValidatedCodes} valides',
                              ),
                              _AnalyticsMetricCard(
                                label: 'Votes traces',
                                value: '${_analytics.totalUsedCodes}',
                                subtitle:
                                    'sur les 7 derniers jours et consultations chargees',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!_isLoading && _analytics.polls.isEmpty)
                            Text(
                              'Aucune donnee analytics disponible pour le moment.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF5A6573)),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 760;
                                final maxDailyVotes =
                                    _analytics.dailyVotes.fold<int>(
                                  0,
                                  (maxValue, item) => item.votes > maxValue
                                      ? item.votes
                                      : maxValue,
                                );
                                final trend = Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: const Color(0xFFD7E0EA)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Votes sur 7 jours',
                                          style: theme.textTheme.titleMedium),
                                      const SizedBox(height: 14),
                                      for (final daily in _analytics.dailyVotes)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
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
                                    border: Border.all(
                                        color: const Color(0xFFD7E0EA)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Participation par consultation',
                                          style: theme.textTheme.titleMedium),
                                      const SizedBox(height: 14),
                                      for (final poll
                                          in _analytics.polls.take(3))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 14),
                                          child: _CompactPollParticipationRow(
                                              poll: poll),
                                        ),
                                    ],
                                  ),
                                );

                                if (wide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: trend),
                                      const SizedBox(width: 16),
                                      Expanded(child: participation),
                                    ],
                                  );
                                }

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    trend,
                                    const SizedBox(height: 16),
                                    participation
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                if (showOverviewSection) const SizedBox(height: 16),
                // ---------- Section Contrôleurs ----------
                if (showControllersSection)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Agents de mobilisation citoyenne',
                                    style: theme.textTheme.titleLarge),
                              ),
                              Chip(label: Text('${_controleurs.length}')),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _openCreateControleurDialog,
                                icon: const Icon(Icons.person_add_rounded,
                                    size: 18),
                                label: const Text('Nouveau'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_controleurs.isEmpty)
                            Text(
                              'Aucun agent de mobilisation citoyenne créé. Utilisez le bouton "Nouveau" pour en créer un.',
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
                if (showControllersSection) const SizedBox(height: 16),
                // ---------- Consultations récentes ----------
                if (showPollsSection)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Consultations recentes',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                              ),
                              if (_isLoading)
                                const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!_isLoading && _polls.isEmpty)
                            const Text(
                                'Aucune consultation disponible pour le moment.')
                          else
                            for (final poll in _polls.take(5))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => Navigator.of(context)
                                      .pushNamed('/admin/poll/${poll.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFFD7E0EA)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(poll.projectTitle,
                                                  style: theme
                                                      .textTheme.titleMedium),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${poll.totalVoted}/${poll.totalVoters} votants · ${poll.status}',
                                                style:
                                                    theme.textTheme.bodyMedium,
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

class _AdminSupportDashboardSection extends StatelessWidget {
  const _AdminSupportDashboardSection({
    required this.communeId,
    required this.onCreateTicket,
    required this.onOpenTickets,
    required this.onOpenTicket,
    required this.onRetry,
  });

  final String communeId;
  final VoidCallback onCreateTicket;
  final VoidCallback onOpenTickets;
  final ValueChanged<SupportTicket> onOpenTicket;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupportTicketService.instance.watchAdminTickets(communeId),
      builder: (context, snapshot) {
        final tickets = snapshot.data ?? const <SupportTicket>[];
        final unread = tickets.where((item) => item.unreadForAdmin).length;
        final latestTickets = tickets.take(3).toList(growable: false);

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SupportSectionHeader(
                    unreadCount: 0,
                    onCreateTicket: onCreateTicket,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      final createCard = _CreateSupportTicketSummaryCard(
                        onCreateTicket: onCreateTicket,
                      );
                      final errorCard = _SupportTicketsErrorCard(
                        onRetry: onRetry,
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: createCard),
                            const SizedBox(width: 16),
                            Expanded(child: errorCard),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          createCard,
                          const SizedBox(height: 14),
                          errorCard,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SupportSectionHeader(
                  unreadCount: unread,
                  onCreateTicket: onCreateTicket,
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final createCard = _CreateSupportTicketSummaryCard(
                      onCreateTicket: onCreateTicket,
                    );
                    final listCard = _SupportTicketsSummaryCard(
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                      tickets: latestTickets,
                      totalTickets: tickets.length,
                      onOpenTickets: onOpenTickets,
                      onOpenTicket: onOpenTicket,
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: createCard),
                          const SizedBox(width: 16),
                          Expanded(child: listCard),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        createCard,
                        const SizedBox(height: 14),
                        listCard,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SupportSectionHeader extends StatelessWidget {
  const _SupportSectionHeader({
    required this.unreadCount,
    required this.onCreateTicket,
  });

  final int unreadCount;
  final VoidCallback onCreateTicket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 610),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _DashboardTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: _DashboardTheme.primary),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text('Assistance',
                              style: theme.textTheme.titleLarge),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Badge(label: Text('$unreadCount')),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Contactez le super administrateur en cas de problème, demande ou besoin d’accompagnement.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onCreateTicket,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouveau ticket'),
        ),
      ],
    );
  }
}

class _CreateSupportTicketSummaryCard extends StatelessWidget {
  const _CreateSupportTicketSummaryCard({required this.onCreateTicket});

  final VoidCallback onCreateTicket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DashboardTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nouveau ticket d’assistance',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Décrivez votre demande avec un sujet, une catégorie, une priorité et un message détaillé.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreateTicket,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Envoyer au super admin'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTicketsSummaryCard extends StatelessWidget {
  const _SupportTicketsSummaryCard({
    required this.isLoading,
    required this.tickets,
    required this.totalTickets,
    required this.onOpenTickets,
    required this.onOpenTicket,
  });

  final bool isLoading;
  final List<SupportTicket> tickets;
  final int totalTickets;
  final VoidCallback onOpenTickets;
  final ValueChanged<SupportTicket> onOpenTicket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DashboardTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Mes tickets', style: theme.textTheme.titleMedium),
              ),
              TextButton(onPressed: onOpenTickets, child: const Text('Tout voir')),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const _SupportLoadingState()
          else if (tickets.isEmpty)
            const _SupportEmptyState()
          else ...[
            for (final ticket in tickets) ...[
              TicketCard(
                ticket: ticket,
                showUnreadForAdmin: true,
                onOpen: () => onOpenTicket(ticket),
              ),
              const SizedBox(height: 10),
            ],
            if (totalTickets > tickets.length)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpenTickets,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text('Voir les $totalTickets tickets'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SupportTicketsErrorCard extends StatelessWidget {
  const _SupportTicketsErrorCard({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DashboardTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes tickets', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          _SupportErrorState(onRetry: onRetry),
        ],
      ),
    );
  }
}

class _SupportEmptyState extends StatelessWidget {
  const _SupportEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aucun ticket d’assistance pour le moment.'),
          SizedBox(height: 4),
          Text('Vous pouvez contacter le super administrateur en créant un ticket.'),
        ],
      ),
    );
  }
}

class _SupportErrorState extends StatelessWidget {
  const _SupportErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Impossible de charger l’assistance pour le moment.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _SupportLoadingState extends StatelessWidget {
  const _SupportLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
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
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 26)),
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: _DashboardTheme.mutedForeground)),
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
    final rate =
        poll.totalVoters == 0 ? 0.0 : poll.totalVoted / poll.totalVoters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(poll.projectTitle,
                    style: Theme.of(context).textTheme.titleSmall)),
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
            child: const Icon(Icons.key_rounded,
                size: 18, color: _DashboardTheme.accent),
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
                    _codeVisible && profile.code.isNotEmpty
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
                            profile.displayCodeMasked.isNotEmpty
                                ? profile.displayCodeMasked
                                : 'Code masqué',
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
                            Text('Utilisé', style: TextStyle(fontSize: 11)),
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
          if (profile.code.isNotEmpty)
            IconButton(
              icon: Icon(
                  _codeVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20),
              onPressed: () => setState(() => _codeVisible = !_codeVisible),
              tooltip: _codeVisible ? 'Masquer' : 'Afficher le code',
            ),
          if (_codeVisible && profile.code.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: profile.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copié.')),
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
          Text('Nouvel agent de mobilisation citoyenne'),
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
                'Un code de connexion unique sera genere automatiquement pour cet agent.',
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
          label: Text(_isSubmitting ? 'Creation...' : 'Creer l\'agent de mobilisation citoyenne'),
        ),
      ],
    );
  }
}
