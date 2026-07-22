import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/poll_models.dart';
import '../../services/citizen_public_access_service.dart';
import '../../services/vote_access_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_bottom_nav.dart';
import '../../widgets/citizen/citizen_card.dart';
import '../../widgets/citizen/citizen_header.dart';
import 'citizen_poll_question_page.dart';

class CitizenConsultationsPage extends StatefulWidget {
  const CitizenConsultationsPage({
    super.key,
    this.initialSession,
    this.voteAccessService,
  });

  final CitizenPublicAccessSession? initialSession;
  final VoteAccessService? voteAccessService;

  @override
  State<CitizenConsultationsPage> createState() =>
      _CitizenConsultationsPageState();
}

class _CitizenConsultationsPageState
    extends State<CitizenConsultationsPage> {
  CitizenPublicAccessSession? get _session =>
      widget.initialSession ?? CitizenPublicAccessService.instance.currentSession;

  List<PollModel> get _polls {
    final polls = List<PollModel>.from(_session?.openPolls ?? const <PollModel>[]);
    polls.sort((a, b) => a.closeDate.compareTo(b.closeDate));
    return polls;
  }

  Future<void> _logoutCitizen() async {
    await CitizenPublicAccessService.instance.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/access', (route) => false);
  }

  void _openConsultation(PollModel poll) {
    if (poll.id.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(
          name: '/citizen/consultation/${Uri.encodeComponent(poll.projectTitle)}',
        ),
        builder: (_) => CitizenPollQuestionPage(
          title: poll.projectTitle,
          pollId: poll.id,
          accessCode: _session?.accessCode,
          voteAccessService: widget.voteAccessService,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final polls = _polls;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
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
                    CitizenHeader(
                      title: 'Donner mon avis',
                      showBack: false,
                      trailing: IconButton(
                        tooltip: 'Se déconnecter',
                        onPressed: _logoutCitizen,
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    Expanded(
                      child: polls.isEmpty
                          ? const _EmptyConsultations()
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 18, 16, 26),
                              itemCount: polls.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final poll = polls[index];
                                return _ConsultationCard(
                                  poll: poll,
                                  onPressed: () => _openConsultation(poll),
                                );
                              },
                            ),
                    ),
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
      ),
    );
  }
}

class _EmptyConsultations extends StatelessWidget {
  const _EmptyConsultations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: CitizenCard(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: CitizenDesignTokens.skyBlue,
                child: Icon(
                  Icons.how_to_vote_outlined,
                  color: CitizenDesignTokens.primaryBlue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Aucune consultation en cours',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CitizenDesignTokens.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Votre commune n’a publié aucune consultation ouverte pour le moment. Revenez prochainement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CitizenDesignTokens.textMuted,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacementNamed(
                  '/citizen/home',
                  arguments: {
                    'session':
                        CitizenPublicAccessService.instance.currentSession,
                  },
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Retour à l’accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.poll, required this.onPressed});

  final PollModel poll;
  final VoidCallback onPressed;

  String get _dateLabel {
    final raw = poll.closeDate.trim();
    if (raw.isEmpty) return 'Date de clôture à confirmer';
    final date = DateTime.tryParse(raw);
    if (date == null) return 'Jusqu’au $raw';
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return 'Jusqu’au ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return CitizenCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('consultationCard_${poll.id}'),
        borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusCard),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: CitizenDesignTokens.skyBlue,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: CitizenDesignTokens.primaryBlue,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poll.projectTitle,
                          style: const TextStyle(
                            color: CitizenDesignTokens.textDark,
                            fontSize: 18,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (poll.question.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            poll.question,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: CitizenDesignTokens.textMuted,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: CitizenDesignTokens.primaryBlue,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _dateLabel,
                      style: const TextStyle(
                        color: CitizenDesignTokens.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 17,
                    color: CitizenDesignTokens.deepBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
