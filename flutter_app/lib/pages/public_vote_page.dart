import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/citizen_public_access_service.dart';
import '../services/poll_service.dart';
import '../widgets/citizen/citizen_bottom_nav.dart';
import '../widgets/citizen_connect_invite.dart';
import '../widgets/debug_log_viewer.dart';
import '../widgets/public_bottom_nav.dart';
import 'public_news_page.dart';
import 'public_results_page.dart';

/// Aperçu public des consultations ouvertes, avant connexion citoyenne.
///
/// Un citoyen non connecté n'a pas encore de code citoyen pour voter : cette
/// page se contente de lister les consultations ouvertes et de l'inviter à
/// rejoindre son espace citoyen, comme les onglets Actualités et Résultats.
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
    setState(() => _isLoading = true);
    List<PollModel> polls = const [];
    try {
      polls = await PollService.instance.loadPolls();
    } catch (_) {
      // PollService catche deja la plupart des erreurs reseau/Firestore ; ce
      // garde-fou evite un ecran bloque sur le spinner si un cas imprevu
      // remonte quand meme une exception.
      polls = const [];
    }
    if (!mounted) return;
    setState(() {
      _openPolls = polls.where((poll) => poll.status == 'active').toList()
        ..sort((left, right) => right.openDate.compareTo(left.openDate));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCitizenSession =
        CitizenPublicAccessService.instance.currentSession != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Donner mon avis'),
        centerTitle: true,
        actions: const [DebugLogButton(label: '')],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
              children: [
                if (!hasCitizenSession)
                  const CitizenConnectInvite(
                    message:
                        'Connectez-vous a votre compte pour donner votre avis sur les consultations de votre commune.',
                  )
                else ...[
                  Text(
                    'Consultations ouvertes de votre commune.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF5A6573)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  if (_isLoading)
                    const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()))
                  else if (_openPolls.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            const Icon(Icons.edit_square,
                                size: 42, color: Color(0xFF5A6573)),
                            const SizedBox(height: 12),
                            Text('Aucune consultation ouverte',
                                style: theme.textTheme.titleLarge),
                            const SizedBox(height: 6),
                            const Text(
                              'Aucune consultation n\'est ouverte pour le moment. Revenez bientôt.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final poll in _openPolls) _OpenPollPreviewCard(poll: poll),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: hasCitizenSession
          ? CitizenBottomNav(
              activeTab: CitizenNavTab.opinion,
              onTabSelected: _onCitizenNav,
            )
          : const PublicBottomNav(currentTab: PublicTab.vote),
    );
  }

  void _onCitizenNav(CitizenNavTab tab) {
    switch (tab) {
      case CitizenNavTab.home:
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/citizen/welcome',
          (route) => route.isFirst,
        );
        break;
      case CitizenNavTab.news:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PublicNewsPage()),
        );
        break;
      case CitizenNavTab.opinion:
        Navigator.of(context).pushNamed('/citizen/consultations');
        break;
      case CitizenNavTab.results:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PublicResultsPage()),
        );
        break;
    }
  }
}

class _OpenPollPreviewCard extends StatelessWidget {
  const _OpenPollPreviewCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(poll.projectTitle, style: theme.textTheme.titleLarge),
              if (poll.communeName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(poll.communeName,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFF5A6573))),
              ],
              if (poll.question.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(poll.question, style: theme.textTheme.bodyLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
