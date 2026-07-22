import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/citizen_public_access_service.dart';
import '../services/poll_service.dart';
import '../theme/citizen_design_tokens.dart';
import '../widgets/citizen/citizen_bottom_nav.dart';
import '../widgets/citizen_connect_invite.dart';
import '../widgets/public_bottom_nav.dart';
import '../widgets/public_page_ui.dart';

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

    return PublicPageShell(
      title: 'Donner mon avis',
      navigationBar: connected
          ? CitizenBottomNav(
              activeTab: CitizenNavTab.opinion,
              onTabSelected: (tab) => CitizenNavigation.open(
                context,
                tab,
                session: session,
              ),
            )
          : const PublicBottomNav(currentTab: PublicTab.vote),
      body: RefreshIndicator(
        color: CitizenDesignTokens.primaryBlue,
        onRefresh: _load,
        child: PublicResponsiveList(
          children: [
            if (!connected)
              const CitizenConnectInvite(
                message:
                    'Connectez-vous avec votre code citoyen pour participer anonymement aux consultations de votre commune.',
              )
            else ...[
              _ConnectedCallToAction(
                count: session.openPolls.length,
                onPressed: _openCitizenConsultations,
              ),
              const SizedBox(height: 18),
            ],
            const PublicPageIntro(
              icon: Icons.how_to_vote_rounded,
              title: 'Consultations ouvertes',
              description:
                  'Découvrez les projets actuellement proposés et connectez-vous pour transmettre votre avis anonymement.',
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const PublicLoadingState()
            else if (_openPolls.isEmpty)
              const PublicEmptyState(
                icon: Icons.event_busy_rounded,
                title: 'Aucune consultation ouverte',
                message:
                    'Revenez prochainement pour découvrir les nouveaux projets soumis à votre avis.',
              )
            else
              for (final poll in _openPolls)
                _OpenPollPreviewCard(
                  poll: poll,
                  onPressed: _openCitizenConsultations,
                ),
          ],
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          padding: EdgeInsets.all(compact ? 16 : 18),
          decoration: CitizenDesignTokens.cardDecoration,
          child: Column(
            children: [
              if (compact) ...[
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: CitizenDesignTokens.skyBlue,
                  child: Icon(
                    Icons.how_to_vote_rounded,
                    color: CitizenDesignTokens.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  count == 0
                      ? 'Aucune consultation disponible pour votre commune.'
                      : '$count consultation${count > 1 ? 's' : ''} disponible${count > 1 ? 's' : ''} pour votre commune.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CitizenDesignTokens.textDark,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else
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
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
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
      },
    );
  }
}

class _OpenPollPreviewCard extends StatelessWidget {
  const _OpenPollPreviewCard({required this.poll, required this.onPressed});

  final PollModel poll;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusCard),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(CitizenDesignTokens.radiusCard),
              onTap: onPressed,
              child: Container(
                padding: EdgeInsets.all(compact ? 16 : 18),
                decoration: CitizenDesignTokens.cardDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: compact ? 24 : 27,
                      backgroundColor: CitizenDesignTokens.skyBlue,
                      child: const Icon(
                        Icons.forum_outlined,
                        color: CitizenDesignTokens.primaryBlue,
                      ),
                    ),
                    SizedBox(width: compact ? 10 : 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poll.projectTitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: CitizenDesignTokens.textDark,
                              fontSize: 16,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (poll.communeName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              poll.communeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CitizenDesignTokens.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: CitizenDesignTokens.deepBlue,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
