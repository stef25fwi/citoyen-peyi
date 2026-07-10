import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/support_ticket.dart';
import '../services/auth_session_store.dart';
import '../services/citizen_access_code_service.dart';
import '../services/commune_lookup_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/push_notification_service.dart';
import '../services/support_ticket_service.dart';
import '../services/super_admin_service.dart';
import '../widgets/commune_autocomplete_field.dart';
import '../widgets/debug_log_viewer.dart';
import '../widgets/super_admin_controller_activity_tile.dart';
import '../widgets/super_admin_duplicate_tile.dart';

enum SuperAdminDashboardSection { overview, admins }

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({
    super.key,
    this.initialSection = SuperAdminDashboardSection.overview,
  });

  final SuperAdminDashboardSection initialSection;

  @override
  State<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  List<AdminProfileModel> _profiles = const [];
  List<DuplicateCodeRequestModel> _duplicateRequests = const [];
  ControllerActivityAnalytics _activityAnalytics =
      const ControllerActivityAnalytics(
    logs: [],
    totalCodesGenerated: 0,
    duplicatesDetected: 0,
    regenerationRequests: 0,
    regenerationsApproved: 0,
    regenerationsRejected: 0,
    loginCodesUsed: 0,
    activityByDay: {},
    activityByController: {},
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    // Enregistre le navigateur du super admin pour les push "nouveau ticket".
    unawaited(PushNotificationService.instance.registerForSuperAdmin());
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);

    List<AdminProfileModel> profiles = _profiles;
    List<DuplicateCodeRequestModel> duplicates = _duplicateRequests;
    ControllerActivityAnalytics analytics = _activityAnalytics;
    Object? loadError;

    try {
      profiles = await SuperAdminService.instance.loadProfiles();
    } catch (error, stackTrace) {
      loadError = error;
      debugPrint('[SuperAdminDashboard] loadProfiles failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      duplicates = await CitizenAccessCodeService.instance
          .getDuplicateRequestsForSuperAdmin();
    } catch (error, stackTrace) {
      debugPrint('[SuperAdminDashboard] duplicates failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      analytics =
          await CitizenAccessCodeService.instance.getControllerAnalytics();
    } catch (error, stackTrace) {
      debugPrint('[SuperAdminDashboard] analytics failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _duplicateRequests = duplicates;
      _activityAnalytics = analytics;
      _isLoading = false;
    });

    if (loadError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Impossible de rafraichir la liste des profils administrateurs: '
            '${loadError.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteProfile(AdminProfileModel profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce profil ?'),
        content: Text(
            'Le profil "${profile.label}" et sa cle de connexion seront supprimes definitivement.'),
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
      await SuperAdminService.instance.deleteProfile(profile.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil "${profile.label}" supprimé.')),
      );
      await _loadProfiles();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Suppression impossible : ${error.toString()}'),
        ),
      );
    }
  }

  Future<void> _openCreateDialog() async {
    final superKey = SuperAdminService.instance.runtimeSuperAdminKey;
    if (superKey == null || superKey.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session super administrateur expirée. Reconnectez-vous pour créer un profil.',
          ),
        ),
      );
      await FirebaseAuthService.instance.signOut();
      await AuthSessionStore.instance.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/super/login');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => _CreateProfileDialog(
        onCreated: (profile) async {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil administrateur créé'),
              backgroundColor: Color(0xFF2B9F82),
            ),
          );
          await _loadProfiles();
          if (!mounted || profile.accessKey.isEmpty) return;
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
        icon: const Icon(Icons.check_circle_rounded,
            color: Color(0xFF2B9F82), size: 40),
        title: const Text('Profil créé avec succès'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Copiez cette clé maintenant pour l\'administrateur de "${profile.communeName}". Elle ne sera plus visible en clair après fermeture.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
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
                        color: Color(0xFF0F6D8F),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        color: Color(0xFF0F6D8F)),
                    tooltip: 'Copier la clé',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.accessKey));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Clé copiée dans le presse-papiers.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (profile.referenceEmail.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'À transmettre à : ${profile.referenceEmail}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF5A6573)),
              ),
            ],
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
    final showOverviewSection =
        widget.initialSection == SuperAdminDashboardSection.overview;
    final pageTitle =
        showOverviewSection ? 'Super Administration' : 'Admins communaux';

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        titleTextStyle: theme.textTheme.titleLarge
            ?.copyWith(color: const Color(0xFF0F6D8F)),
        leading: const Icon(Icons.admin_panel_settings_rounded,
            color: Color(0xFF0F6D8F)),
        leadingWidth: 56,
        actions: [
          const DebugLogButton(),
          _SupportNavBadge(
            onTap: () =>
                Navigator.of(context).pushNamed('/super-admin/support'),
          ),
          TextButton(
            onPressed: () async {
              SuperAdminService.instance.clearRuntimeSuperAdminKey();
              try {
                await FirebaseAuthService.instance.signOut();
              } catch (error, stackTrace) {
                debugPrint('[SuperAdminDashboard] signOut failed: $error');
                debugPrintStack(stackTrace: stackTrace);
              }
              try {
                await AuthSessionStore.instance.clear();
              } catch (error, stackTrace) {
                debugPrint(
                    '[SuperAdminDashboard] session clear failed: $error');
                debugPrintStack(stackTrace: stackTrace);
              }
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text('Deconnexion'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: RefreshIndicator(
            onRefresh: _loadProfiles,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(6, 20, 6, 100),
              children: [
                // Session card
                Card(
                  color: const Color(0xFFE0F2FE),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded,
                            color: Color(0xFF0F6D8F), size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session?.label ?? 'Super Administrateur',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF0F6D8F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Role: ${session?.role ?? '-'}  •  Mode: ${session?.modeLabel ?? '-'}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF0891B2)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Vue d\'ensemble'),
                      selected: widget.initialSection ==
                          SuperAdminDashboardSection.overview,
                      onSelected: (_) =>
                          Navigator.of(context).pushNamed('/super'),
                    ),
                    ChoiceChip(
                      label: const Text('Admins communaux'),
                      selected: widget.initialSection ==
                          SuperAdminDashboardSection.admins,
                      onSelected: (_) =>
                          Navigator.of(context).pushNamed('/super/admins'),
                    ),
                  ],
                ),
                if (showOverviewSection) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.analytics_rounded,
                          color: Color(0xFF0F6D8F)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Donnees analytics superadmin',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vue globale des doublons citoyens, regenerations et activites des agents de mobilisation citoyenne par commune.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF5A6573)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonal(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/super/communes'),
                        child: const Text('Communes'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/super/admins'),
                        child: const Text('Admins communaux'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context)
                            .pushNamed('/super/controllers'),
                        child: const Text('Agents de mobilisation citoyenne'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context)
                            .pushNamed('/super/duplicates'),
                        child: const Text('Doublons'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/super/activity'),
                        child: const Text('Activite'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context)
                            .pushNamed('/super-admin/support'),
                        child: const Text('Tickets assistance'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/super/backups'),
                        child: const Text('Sauvegardes'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SuperAdminSupportDashboardCard(
                    onOpen: () =>
                        Navigator.of(context).pushNamed('/super-admin/support'),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final pendingDuplicates = _duplicateRequests
                          .where((item) => item.status == 'pending')
                          .length;
                      final duplicateTile = SuperAdminDuplicateTile(
                        pendingCount: pendingDuplicates,
                        latestRequests: _duplicateRequests,
                        onOpen: () => Navigator.of(context)
                            .pushNamed('/super/duplicates'),
                      );
                      final activityTile = SuperAdminControllerActivityTile(
                        analytics: _activityAnalytics,
                        onOpen: () =>
                            Navigator.of(context).pushNamed('/super/activity'),
                      );

                      if (constraints.maxWidth >= 760) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: duplicateTile),
                            const SizedBox(width: 16),
                            Expanded(child: activityTile),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          duplicateTile,
                          const SizedBox(height: 16),
                          activityTile
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  children: [
                    Text(
                      'Profils administrateurs',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 12),
                    Chip(label: Text('${_profiles.length}')),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6D8F)),
                      onPressed: () => _openCreateDialog(),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Nouveau profil'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Chaque profil est rattache a une commune et possede une cle de connexion unique.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFF5A6573)),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator()))
                else if (_profiles.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          const Icon(Icons.group_outlined,
                              size: 48, color: Color(0xFF9AA9B8)),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun profil administrateur cree.',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: const Color(0xFF5A6573)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Utilisez le bouton + en bas a droite pour creer le premier profil.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF9AA9B8)),
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

class _SupportNavBadge extends StatelessWidget {
  const _SupportNavBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SupportTicket>>(
      stream: SupportTicketService.instance.watchUnreadTicketsForSuperAdmin(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return IconButton(
          tooltip:
              count > 0 ? '$count ticket(s) non lu(s)' : 'Tickets assistance',
          onPressed: onTap,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.support_agent_rounded,
                color: Color(0xFF0F6D8F)),
          ),
        );
      },
    );
  }
}

class _SuperAdminSupportDashboardCard extends StatelessWidget {
  const _SuperAdminSupportDashboardCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<SupportTicket>>(
      stream: SupportTicketService.instance.watchAllTicketsForSuperAdmin(),
      builder: (context, snapshot) {
        final tickets = snapshot.data ?? const <SupportTicket>[];
        final unread = tickets.where((item) => item.unreadForSuperAdmin).length;
        final urgent = tickets
            .where(
                (item) => item.priority == 'urgente' && item.status != 'ferme')
            .length;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0D73F2).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.support_agent_rounded,
                              color: Color(0xFF0D73F2)),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tickets assistance',
                                  style: theme.textTheme.titleLarge),
                              const SizedBox(height: 4),
                              const Text(
                                  'Suivez les demandes des administrateurs communaux.'),
                              if (snapshot.hasError) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Compteurs indisponibles pour le moment.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFFB45309)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (unread > 0) Badge(label: Text('$unread non lu(s)')),
                      if (urgent > 0)
                        Badge(
                          backgroundColor: const Color(0xFFDC2626),
                          label: Text('$urgent urgent(s)'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------- Profile card ----------

/// Format jj/mm/aa hh:mm (heure locale) pour l'affichage des profils.
String _formatFrenchDateTime(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${two(d.year % 100)} '
      '${two(d.hour)}:${two(d.minute)}';
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.profile, required this.onDelete});

  final AdminProfileModel profile;
  final VoidCallback onDelete;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _keyVisible = false;
  bool _busy = false;
  String? _revealedKey;

  @override
  void initState() {
    super.initState();
    if (widget.profile.accessKey.isNotEmpty) {
      _revealedKey = widget.profile.accessKey;
    }
  }

  String get _key => _revealedKey ?? '';

  Future<void> _onEyePressed() async {
    if (_key.isNotEmpty) {
      setState(() => _keyVisible = !_keyVisible);
      return;
    }
    await _regenerateAndReveal();
  }

  Future<void> _regenerateAndReveal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Afficher la clé ?'),
        content: const Text(
          'Pour des raisons de sécurité, la clé d\'origine est chiffrée et ne '
          'peut pas être réaffichée. Générer une nouvelle clé pour cet '
          'administrateur ? L\'ancienne clé sera immédiatement invalidée.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Générer & afficher'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final key = await SuperAdminService.instance
          .regenerateAdminKey(widget.profile.id);
      if (!mounted) return;
      setState(() {
        _revealedKey = key;
        _keyVisible = true;
        _busy = false;
      });
    } on SuperAdminAuthException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Régénération impossible : ${error.message}'),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[SuperAdminDashboard] regenerate admin key failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text(
            'Régénération impossible : erreur technique. Reconnectez-vous puis réessayez.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;

    final createdDate = _formatFrenchDateTime(profile.createdAt);

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
                  child: const Icon(Icons.manage_accounts_rounded,
                      color: Color(0xFF0F6D8F)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.label,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${profile.communeName}${profile.codePostal != null ? " (${profile.codePostal})" : ""}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: const Color(0xFF5A6573)),
                      ),
                      if (profile.referenceEmail.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.alternate_email_rounded,
                                size: 14, color: Color(0xFF5A6573)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                profile.referenceEmail,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF5A6573)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
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
                  child: _keyVisible && _key.isNotEmpty
                      ? SelectableText(
                          _key,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 1.1,
                            color: Color(0xFF0F6D8F),
                          ),
                        )
                      : Text(
                          _key.isEmpty
                              ? 'Clé chiffrée — cliquez sur l\'œil pour en générer une nouvelle'
                              : '•' * _key.length,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9AA9B8),
                            letterSpacing: 1,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                if (_busy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(_keyVisible && _key.isNotEmpty
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    tooltip: _key.isEmpty
                        ? 'Générer et afficher la clé'
                        : (_keyVisible ? 'Masquer la clé' : 'Afficher la clé'),
                    onPressed: _onEyePressed,
                  ),
                if (_keyVisible && _key.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: 'Copier la clé',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _key));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Clé copiée dans le presse-papiers.')),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cree le $createdDate',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF9AA9B8)),
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

  final Future<void> Function(AdminProfileModel) onCreated;

  @override
  State<_CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<_CreateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _communeCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isSubmitting = false;

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[CreateProfileDialog] $message');
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _communeCtrl.dispose();
    _codeCtrl.dispose();
    _postalCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _selectCommune(CommuneSuggestion commune) {
    setState(() {
      _communeCtrl.text = commune.nom;
      _postalCtrl.text = commune.firstPostal;
      _codeCtrl.text = commune.code;
      // Pré-remplit le libellé si encore vide ou générique
      if (_labelCtrl.text.trim().isEmpty ||
          _labelCtrl.text.trim().toLowerCase().startsWith('mairie de ')) {
        _labelCtrl.text = 'Mairie de ${commune.nom}';
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF7F1D1D)),
        ),
        backgroundColor: const Color(0xFFFFCDD2),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    debugPrint('[CreateProfileDialog] submit clicked');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Création du profil en cours…'),
          duration: Duration(seconds: 2),
        ),
      );

    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Veuillez renseigner tous les champs obligatoires.');
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      _debugLog('Tentative de création profil administrateur.');
      debugPrint('[CreateProfileDialog] appel createAdminProfile');
      final profile = await SuperAdminService.instance.createAdminProfile(
        label: _labelCtrl.text.trim(),
        communeName:
            CommuneLookupService.normalizeCommuneName(_communeCtrl.text),
        communeCode: CommuneLookupService.normalizeInsee(_codeCtrl.text),
        codePostal: CommuneLookupService.normalizePostal(_postalCtrl.text),
        referenceEmail: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onCreated(profile);
    } on SuperAdminAuthException catch (e) {
      _debugLog('Erreur catchée: ${e.message}');
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (error) {
      _debugLog('Erreur catchée: $error');
      if (!mounted) return;
      _showErrorSnackBar(error.toString());
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
              CommuneAutocompleteField(
                controller: _communeCtrl,
                enabled: !_isSubmitting,
                onSelected: _selectCommune,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
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
                        labelText: 'Code postal *',
                        hintText: '97122',
                        prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Champ requis.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtrl,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Code INSEE *',
                        hintText: '97109',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Champ requis.'
                          : null,
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
                  labelText: 'Libellé du profil *',
                  hintText: 'Ex : Mairie de Baie-Mahault',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
              ),
              const SizedBox(height: 14),
              // ---------- E-mail de reference (optionnel) ----------
              TextFormField(
                controller: _emailCtrl,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail de référence (optionnel)',
                  hintText: 'mairie@exemple.fr',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                  helperText:
                      'Adresse à qui transmettre la clé (aucun envoi automatique).',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return null; // optionnel
                  final ok =
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
                  return ok ? null : 'E-mail invalide.';
                },
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
          style:
              FilledButton.styleFrom(backgroundColor: const Color(0xFF0F6D8F)),
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_isSubmitting ? 'Création…' : 'Créer le profil'),
        ),
      ],
    );
  }
}
