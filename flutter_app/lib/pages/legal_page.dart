import 'package:flutter/material.dart';

import '../widgets/public_bottom_nav.dart';
import 'access_citizen_page.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  static const routeName = '/legal';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text('Informations légales'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.gavel_rounded,
                            color: Color(0xFF0D73F2),
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'CGU, confidentialité, anonymat et données personnelles',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      const _LegalSection(
                        title: 'Participation citoyenne',
                        body:
                            'Citoyen Peyi permet aux citoyens de participer à des consultations publiques organisées par leur collectivité. Le code citoyen sert à sécuriser l’accès et à limiter les participations multiples.',
                      ),
                      const _LegalSection(
                        title: 'Confidentialité',
                        body:
                            'Votre participation est traitée de manière confidentielle. Les informations liées à l’accès sont utilisées uniquement pour vérifier l’éligibilité à la consultation.',
                      ),
                      const _LegalSection(
                        title: 'Principe d’anonymat',
                        body:
                            'Les réponses sont exploitées sous forme statistique ou agrégée. Le choix exprimé n’a pas vocation à être affiché publiquement avec votre identité.',
                      ),
                      const _LegalSection(
                        title: 'Données personnelles',
                        body:
                            'Les données nécessaires au fonctionnement du service sont limitées à la sécurisation de l’accès, à la prévention des doublons et à la production de résultats agrégés.',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          key: const ValueKey('legalAcknowledgementButton'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D73F2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                              return;
                            }
                            Navigator.of(context).pushReplacementNamed(
                                AccessCitizenPage.routeName);
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('J’ai pris connaissance'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const PublicBottomNav(currentTab: PublicTab.vote),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF0D73F2),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF0F172A),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
