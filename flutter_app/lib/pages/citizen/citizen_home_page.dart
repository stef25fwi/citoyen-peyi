import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/citizen_public_access_service.dart';
import '../../services/new_poll_badge_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_bottom_nav.dart';
import '../../widgets/citizen/citizen_card.dart';
import '../legal_page.dart';
import '../public_news_page.dart';
import '../public_results_page.dart';
import 'citizen_consultations_page.dart';

class CitizenHomePage extends StatelessWidget {
  const CitizenHomePage({
    super.key,
    this.initialSession,
  });

  final CitizenPublicAccessSession? initialSession;

  static const String flowerLogoAsset =
      'assets/citoyen_peyi/cp_logo_flower.svg';
  static const String opinionSecureAsset =
      'assets/citoyen_peyi/cp_illustration_opinion_secure.svg';

  void _onNav(BuildContext context, CitizenNavTab tab) {
    if (tab == CitizenNavTab.home) {
      Navigator.of(context).pushReplacementNamed(
        '/citizen/welcome',
        arguments: {'session': initialSession},
      );
      return;
    }

    if (tab == CitizenNavTab.opinion) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CitizenConsultationsPage(initialSession: initialSession),
        ),
      );
      return;
    }

    if (tab == CitizenNavTab.news) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublicNewsPage()),
      );
      return;
    }

    if (tab == CitizenNavTab.results) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublicResultsPage()),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      body: _MobileFrame(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _HomeHeader(
                communeName: initialSession?.communeName,
                initialSession: initialSession,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: _QuickActionsPanel(initialSession: initialSession),
                      ),
                      const SizedBox(height: 2),
                      const _OpinionInfoCard(),
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
      ),
    );
  }
}

class _MobileFrame extends StatelessWidget {
  const _MobileFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: child,
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({this.communeName, this.initialSession});

  final String? communeName;
  final CitizenPublicAccessSession? initialSession;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Menu',
                  onPressed: () async {
                    final shouldLogout = await showModalBottomSheet<bool>(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      builder: (sheetContext) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Session citoyenne',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: CitizenDesignTokens.textDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(
                                    Icons.logout_rounded,
                                    color: CitizenDesignTokens.deepBlue,
                                  ),
                                  title: const Text('Se déconnecter'),
                                  subtitle: const Text(
                                    'Rester connecté jusqu’à une déconnexion manuelle.',
                                  ),
                                  onTap: () =>
                                      Navigator.of(sheetContext).pop(true),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    if (shouldLogout != true || !context.mounted) return;
                    await CitizenPublicAccessService.instance.clearSession();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/access',
                      (route) => false,
                    );
                  },
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MiniFlowerLogo(size: 48),
                        SizedBox(width: 8),
                        _SmallAppTitle(),
                      ],
                    ),
                  ),
                ),
                _NotificationsBell(initialSession: initialSession),
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
            const Text(
              'Exprimez-vous, contribuez, participez\nà la vie de votre collectivité.',
              textAlign: TextAlign.center,
              style: TextStyle(
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

class _NotificationsBell extends StatefulWidget {
  const _NotificationsBell({this.initialSession});

  final CitizenPublicAccessSession? initialSession;

  @override
  State<_NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<_NotificationsBell> {
  final _badgeSvc = NewPollBadgeService.instance;

  @override
  void initState() {
    super.initState();
    _badgeSvc.startListening();
  }

  void _openConsultations(BuildContext context) {
    _badgeSvc.markAllSeen();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CitizenConsultationsPage(initialSession: widget.initialSession),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _badgeSvc.hasNew,
      builder: (context, hasNew, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Nouvelles consultations',
              onPressed: () => _openConsultations(context),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            if (hasNew)
              Positioned(
                right: 9,
                top: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: CitizenDesignTokens.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CitizenDesignTokens.deepBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({this.initialSession});

  final CitizenPublicAccessSession? initialSession;

  @override
  Widget build(BuildContext context) {
    return CitizenCard(
      padding: const EdgeInsets.all(14),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.04,
        children: [
          _QuickActionCard(
            icon: Icons.campaign_rounded,
            title: 'Actualités',
            subtitle: 'Suivez les dernières\ninformations',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PublicNewsPage()),
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
            title: 'Résultats',
            subtitle: 'Découvrez les résultats\ndes consultations',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PublicResultsPage()),
              );
            },
          ),
          _QuickActionCard(
            icon: Icons.info_rounded,
            title: 'À propos',
            subtitle: 'En savoir plus sur la\nplateforme',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LegalPage()),
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
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CitizenDesignTokens.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12005A9C),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 44, color: CitizenDesignTokens.primaryBlue),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CitizenDesignTokens.textDark,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CitizenDesignTokens.textDark,
                      fontSize: 12,
                      height: 1.22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpinionInfoCard extends StatelessWidget {
  const _OpinionInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CitizenDesignTokens.skyBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CitizenDesignTokens.cardBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SvgPicture.asset(
              CitizenHomePage.opinionSecureAsset,
              width: 104,
              height: 78,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre opinion compte !',
                  style: TextStyle(
                    color: CitizenDesignTokens.deepBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Chaque avis est important\npour améliorer notre\nterritoire.',
                  style: TextStyle(
                    color: CitizenDesignTokens.textDark,
                    fontSize: 13,
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
    return SvgPicture.asset(
      CitizenHomePage.flowerLogoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
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
