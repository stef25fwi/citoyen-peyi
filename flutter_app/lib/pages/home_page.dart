import 'package:flutter/material.dart';

import '../widgets/feature_card.dart';
import '../widgets/public_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 920;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFF08354A),
              ),
              child: Stack(
                children: [
                  // Fond d'écran
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/fondecran.png',
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.45),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, isWide ? 120 : 88, 20, isWide ? 96 : 56),
                        child: Column(
                          children: [
                            // Logo
                            Image.asset(
                              'assets/images/lastlogo.png',
                              height: isWide ? 96 : 72,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Plateforme de sondage anonyme',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 780),
                              child: Text(
                                'Votez en toute confidentialite',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: isWide ? 68 : 42,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Text(
                                "Votre collectivite place votre parole au coeur de l'action publique : une solution moderne pour recueillir l'avis de vos parties prenantes, dans un cadre garantissant l'anonymat total et la transparence des resultats.",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pushNamed('/admin/login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF0F6D8F),
                                  ),
                                  child: const Text('Espace Admin'),
                                ),
                                OutlinedButton(
                                  onPressed: () => Navigator.of(context).pushNamed('/controleur/login'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Espace Controleur'),
                                ),
                                OutlinedButton(
                                  onPressed: () => Navigator.of(context).pushNamed('/access'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Acceder avec un QR Code'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 32),
                  child: Column(
                    children: [
                      Text(
                        'Comment ca fonctionne ?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Un processus simple, securise et entierement anonyme.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF5A6573)),
                      ),
                      const SizedBox(height: 28),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 900
                              ? 4
                              : constraints.maxWidth >= 620
                                  ? 2
                                  : 1;

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: columns,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: columns == 1 ? 1.6 : 1.15,
                            children: const [
                              FeatureCard(
                                icon: Icons.how_to_vote_rounded,
                                title: 'Vote simple',
                                description: 'Interface intuitive pour voter en quelques secondes.',
                                accent: Color(0xFF0F6D8F),
                              ),
                              FeatureCard(
                                icon: Icons.verified_user_rounded,
                                title: 'Anonymat garanti',
                                description: 'Architecture separant identite et bulletin de vote.',
                                accent: Color(0xFF2B9F82),
                              ),
                              FeatureCard(
                                icon: Icons.qr_code_2_rounded,
                                title: 'Acces par QR code',
                                description: 'Chaque participant recoit un QR code unique et personnel.',
                                accent: Color(0xFFE58F2A),
                              ),
                              FeatureCard(
                                icon: Icons.bar_chart_rounded,
                                title: 'Resultats en temps reel',
                                description: 'Tableau de bord avec resultats agreges et taux de participation.',
                                accent: Color(0xFF7E57C2),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE6EBF2))),
                color: Color(0xFFF0F5F9),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.shield_rounded, size: 44, color: theme.colorScheme.primary),
                            const SizedBox(height: 14),
                            Text(
                              'Anonymat preserve',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Cette base Flutter reprend la promesse fonctionnelle de l\'application existante : separer l\'identite du vote, limiter les acces sensibles et rendre le parcours lisible sur mobile comme sur desktop.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF5A6573)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE6EBF2))),
                color: Colors.white,
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Column(
                    children: [
                      Text('© 2026 VoteAnonyme - Plateforme de sondage confidentielle'),
                      SizedBox(height: 6),
                      Text('Mode demonstration - Aucune donnee reelle n\'est collectee'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PublicBottomNav(currentTab: PublicTab.home),
    );
  }
}
