import 'package:flutter/material.dart';

import '../../services/citizen_public_access_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_bottom_nav.dart';
import '../../widgets/citizen/citizen_card.dart';
import 'citizen_consultations_page.dart';

class CitizenHomePage extends StatelessWidget {
  const CitizenHomePage({
    super.key,
    this.initialSession,
  });

  final CitizenPublicAccessSession? initialSession;

  void _onNav(BuildContext context, CitizenNavTab tab) {
    if (tab == CitizenNavTab.home) return;

    if (tab == CitizenNavTab.opinion) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CitizenConsultationsPage(initialSession: initialSession),
        ),
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
    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(communeName: initialSession?.communeName),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -18),
                      child: _QuickActionsGrid(initialSession: initialSession),
                    ),
                    const SizedBox(height: 2),
                    _OpinionInfoCard(communeName: initialSession?.communeName),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            CitizenBottomNav(
              activeTab: CitizenNavTab.home,
              onTabSelected: (tab) => _onNav(context, tab),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({this.communeName});

  final String? communeName;

  @override
  Widget build(BuildContext context) {
    final safeCommune = (communeName ?? '').trim();

    return Container(
      height: 238,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: CitizenDesignTokens.headerGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MiniFlowerLogo(size: 48),
                        SizedBox(width: 8),
                        _SmallAppTitle(),
                      ],
                    ),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 4,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: CitizenDesignTokens.yellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(
                            color: CitizenDesignTokens.deepBlue,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const Text(
              'Bienvenue !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              safeCommune.isEmpty
                  ? 'Exprimez-vous, contribuez, participez\na la vie de votre collectivite.'
                  : 'Exprimez-vous pour votre commune\net participez a la vie locale.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({this.initialSession});

  final CitizenPublicAccessSession? initialSession;

  @override
  Widget build(BuildContext context) {
    return CitizenCard(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95,
        children: [
          _QuickActionCard(
            icon: Icons.campaign_rounded,
            title: 'Actualites',
            subtitle: 'Suivez les dernieres\ninformations',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Page Actualites a connecter.')),
              );
            },
          ),
          _QuickActionCard(
            icon: Icons.chat_bubble_rounded,
            title: 'Donner mon avis',
            subtitle: 'Participez aux sondages\net consultations',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CitizenConsultationsPage(
                    initialSession: initialSession,
                  ),
                ),
              );
            },
          ),
          _QuickActionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Resultats',
            subtitle: 'Decouvrez les resultats\ndes consultations',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Page Resultats a connecter.')),
              );
            },
          ),
          _QuickActionCard(
            icon: Icons.info_rounded,
            title: 'A propos',
            subtitle: 'En savoir plus sur la\nplateforme',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Page A propos a connecter.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CitizenCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: CitizenDesignTokens.primaryBlue),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CitizenDesignTokens.textDark,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CitizenDesignTokens.textDark,
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpinionInfoCard extends StatelessWidget {
  const _OpinionInfoCard({this.communeName});

  final String? communeName;

  @override
  Widget build(BuildContext context) {
    final subtitle = (communeName ?? '').trim().isEmpty
        ? 'Chaque avis est important\npour ameliorer notre\nterritoire.'
        : 'Chaque avis est important\npour ameliorer votre\ncommune.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: CitizenDesignTokens.softBlueDecoration,
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 48,
              color: CitizenDesignTokens.primaryBlue,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Votre opinion compte !',
                  style: TextStyle(
                    color: CitizenDesignTokens.deepBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: CitizenDesignTokens.textDark,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFlowerLogo extends StatelessWidget {
  const _MiniFlowerLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 7; i++)
            Transform.rotate(
              angle: i * 0.9,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: size * 0.28,
                  height: size * 0.45,
                  decoration: BoxDecoration(
                    color: i == 1
                        ? CitizenDesignTokens.yellow
                        : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
            ),
          Container(
            width: size * 0.14,
            height: size * 0.14,
            decoration: const BoxDecoration(
              color: CitizenDesignTokens.yellow,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAppTitle extends StatelessWidget {
  const _SmallAppTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
        children: [
          TextSpan(text: 'Citoyen ', style: TextStyle(color: Colors.white)),
          TextSpan(
            text: 'Peyi',
            style: TextStyle(color: CitizenDesignTokens.yellow),
          ),
        ],
      ),
    );
  }
}
