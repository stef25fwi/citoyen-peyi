import 'package:flutter/material.dart';

import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_bottom_nav.dart';
import '../../widgets/citizen/citizen_card.dart';
import '../../widgets/citizen/citizen_header.dart';
import '../../widgets/citizen/citizen_primary_button.dart';
import '../../widgets/citizen/question_option_tile.dart';
import 'citizen_consultations_page.dart';
import 'citizen_home_page.dart';

class CitizenPollQuestionPage extends StatefulWidget {
  const CitizenPollQuestionPage({
    super.key,
    required this.title,
    this.pollId,
    this.accessCode,
  });

  final String title;
  final String? pollId;
  final String? accessCode;

  @override
  State<CitizenPollQuestionPage> createState() =>
      _CitizenPollQuestionPageState();
}

class _CitizenPollQuestionPageState extends State<CitizenPollQuestionPage> {
  final Set<String> selectedOptions = {
    'Espaces verts et parcs',
    'Eclairage public',
    'Accessibilite PMR',
  };

  bool get canContinue => selectedOptions.isNotEmpty;
  bool get otherSelected => selectedOptions.contains('Autre');

  void _toggle(String label) {
    setState(() {
      if (selectedOptions.contains(label)) {
        selectedOptions.remove(label);
      } else {
        selectedOptions.add(label);
      }
    });
  }

  void _onNav(CitizenNavTab tab) {
    if (tab == CitizenNavTab.opinion) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CitizenConsultationsPage()),
      );
      return;
    }

    if (tab == CitizenNavTab.home) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CitizenHomePage()),
        (route) => route.isFirst,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tab == CitizenNavTab.news
              ? 'Page Actualites a connecter.'
              : 'Page Resultats a connecter.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerTitle = widget.title == 'Amenagement des espaces publics'
        ? 'Amenagement des\nespaces publics'
        : widget.title;

    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CitizenHeader(
              title: headerTitle,
              trailing: IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partage a connecter.')),
                  );
                },
                icon: const Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Etape 1 sur 6',
                      style: TextStyle(
                        color: CitizenDesignTokens.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 1 / 6,
                        minHeight: 8,
                        backgroundColor: CitizenDesignTokens.skyBlue,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          CitizenDesignTokens.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    CitizenCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Quels sont les amenagements\n'
                            'que vous jugez prioritaires dans\n'
                            'votre commune ?',
                            style: TextStyle(
                              color: CitizenDesignTokens.textDark,
                              fontSize: 18,
                              height: 1.22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Vous pouvez choisir plusieurs reponses',
                            style: TextStyle(
                              color: CitizenDesignTokens.textMuted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          QuestionOptionTile(
                            label: 'Espaces verts et parcs',
                            icon: Icons.park_rounded,
                            selected:
                                selectedOptions.contains('Espaces verts et parcs'),
                            onTap: () => _toggle('Espaces verts et parcs'),
                          ),
                          QuestionOptionTile(
                            label: 'Eclairage public',
                            icon: Icons.lightbulb_outline_rounded,
                            selected:
                                selectedOptions.contains('Eclairage public'),
                            onTap: () => _toggle('Eclairage public'),
                          ),
                          QuestionOptionTile(
                            label: 'Aires de jeux',
                            icon: Icons.sports_esports_rounded,
                            selected: selectedOptions.contains('Aires de jeux'),
                            onTap: () => _toggle('Aires de jeux'),
                          ),
                          QuestionOptionTile(
                            label: 'Accessibilite PMR',
                            icon: Icons.accessible_forward_rounded,
                            selected:
                                selectedOptions.contains('Accessibilite PMR'),
                            onTap: () => _toggle('Accessibilite PMR'),
                          ),
                          QuestionOptionTile(
                            label: 'Autre',
                            icon: Icons.more_horiz_rounded,
                            selected: selectedOptions.contains('Autre'),
                            onTap: () => _toggle('Autre'),
                          ),
                          if (otherSelected) ...[
                            const SizedBox(height: 2),
                            TextField(
                              minLines: 2,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Precisez votre reponse',
                                filled: true,
                                fillColor: CitizenDesignTokens.lightBlue,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: CitizenDesignTokens.cardBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: CitizenDesignTokens.cardBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: CitizenDesignTokens.primaryBlue,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          CitizenPrimaryButton(
                            label: 'Suivant',
                            showArrow: true,
                            enabled: canContinue,
                            onPressed: canContinue ? _submitOrContinue : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CitizenBottomNav(
              activeTab: CitizenNavTab.opinion,
              onTabSelected: _onNav,
            ),
          ],
        ),
      ),
    );
  }

  void _submitOrContinue() {
    final accessCode = widget.accessCode;
    final pollId = widget.pollId;

    if (accessCode != null && accessCode.isNotEmpty && pollId != null && pollId.isNotEmpty) {
      final routeCode = Uri.encodeComponent(accessCode);
      final routePollId = Uri.encodeQueryComponent(pollId);
      Navigator.of(context).pushNamed('/vote/$routeCode?poll=$routePollId');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Merci ! Votre avis a bien ete pris en compte.'),
      ),
    );
  }
}
