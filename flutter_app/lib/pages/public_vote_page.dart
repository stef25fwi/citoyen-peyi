import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/poll_models.dart';
import '../services/citizen_public_access_service.dart';
import '../services/poll_service.dart';
import '../theme/citizen_design_tokens.dart';
import '../widgets/citizen/citizen_bottom_nav.dart';
import '../widgets/citizen/citizen_header.dart';
import '../widgets/citizen_connect_invite.dart';
import '../widgets/debug_log_viewer.dart';
import '../widgets/public_bottom_nav.dart';

class PublicVotePage extends StatefulWidget {
  const PublicVotePage({super.key});

  @override
  State<PublicVotePage> createState() => _PublicVotePageState();
}

class _PublicVotePageState extends State<PublicVotePage> {
  bool _isLoading = true;
  List<PollModel> _openPolls = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final polls = await PollService.instance.loadPolls();
      if (!mounted) return;
      setState(() {
        _openPolls = polls
            .where((poll) => poll.status == 'active' || poll.status == 'open')
            .toList()
          ..sort((a, b) => b.openDate.compareTo(a.openDate));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _openPolls = const [];
        _isLoading = false;
      });
    }
  }

  void _openCitizenConsultations() {
    final session = CitizenPublicAccessService.instance.currentSession;
    Navigator.of(context).pushReplacementNamed(
      session == null ? '/access' : '/citizen/consultations',
      arguments: {'session': session},
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = CitizenPublicAccessService.instance.currentSession;
    final connected = session != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              bottom: false,
              child: ColoredBox(
                color: CitizenDesignTokens.background,
                child: Column(
                  children: [
                    const CitizenHeader(
                      title: 'Donner mon avis',
                      showBack: false,
                      trailing: DebugLogButton(label: ''),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: CitizenDesignTokens.primaryBlue,
                        onRefresh: _load,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                          children: [
                            if (!connected)
                              const CitizenConnectInvite(
                                message:
                                    'Connectez-vous avec votre code citoyen pour participer anonymement aux consultations de votre commune.',
                              )
                            else
                              _ConnectedCallToAction(
                                count: session.openPolls.length,
                                onPressed: _openCitizenConsultations,
                              ),
                            const SizedBox(height: 18),
                            const Text(
                              'Consultations actuellement ouvertes',
                              style: TextStyle(
                                color: CitizenDesignTokens.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.all(34),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_openPolls.isEmpty)
                              const _EmptyPublicPolls()
                            else
                              for (final poll in _openPolls)
                                _OpenPollPreviewCard(
                                  poll: poll,
                                  onPressed: _openCitizenConsultations,
                                ),
                          ],
                        ),
                      ),
                    ),
                    if (connected)
                      CitizenBottomNav(
                        activeTab: CitizenNavTab.opinion,
                        onTabSelected: (tab) => CitizenNavigation.open(
                          context,
                          tab,
                          session: session,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: connected
            ? null
            : const PublicBottomNav(currentTab: PublicTab.vote),
      ),
    );
  }
}

class _ConnectedCallToAction extends StatelessWidget {
  const _ConnectedCallToAction({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: CitizenDesignTokens.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: CitizenDesignTokens.skyBlue,
                child: Icon(
                  Icons.how_to_vote_rounded,
                  color: CitizenDesignTokens.primaryBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  count == 0
                      ? 'Aucune consultation disponible pour votre commune.'
                      : '$count consultation${count > 1 ? 's' : ''} disponible${count > 1 ? 's' : ''} pour votre commune.',
                  style: const TextStyle(
                    color: CitizenDesignTokens.textDark,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Accéder à mes consultations'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPublicPolls extends StatelessWidget {
  const _EmptyPublicPolls();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: CitizenDesignTokens.cardDecoration,
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 42,
            color: CitizenDesignTokens.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            'Aucune consultation ouverte',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CitizenDesignTokens.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Revenez prochainement pour découvrir les nouveaux projets soumis à votre avis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CitizenDesignTokens.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenPollPreviewCard extends StatelessWidget {
  const _OpenPollPreviewCard({required this.poll, required this.onPressed});

  final PollModel poll;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusCard),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: CitizenDesignTokens.cardDecoration,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: CitizenDesignTokens.skyBlue,
                  child: Icon(
                    Icons.forum_outlined,
                    color: CitizenDesignTokens.primaryBlue,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poll.projectTitle,
                        style: const TextStyle(
                          color: CitizenDesignTokens.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (poll.communeName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          poll.communeName,
                          style: const TextStyle(
                            color: CitizenDesignTokens.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.lock_outline_rounded,
                  color: CitizenDesignTokens.deepBlue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
