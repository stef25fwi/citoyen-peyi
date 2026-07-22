import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/citizen_public_access_service.dart';
import '../../services/new_poll_badge_service.dart';
import '../../services/vote_access_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_bottom_nav.dart';
import '../legal_page.dart';
import 'citizen_consultations_page.dart';
import 'citizen_profile_page.dart';

class CitizenHomePage extends StatelessWidget {
  const CitizenHomePage({
    super.key,
    this.initialSession,
    this.voteAccessService,
  });

  final CitizenPublicAccessSession? initialSession;
  final VoteAccessService? voteAccessService;

  static const String flowerLogoAsset =
      'assets/citoyen_peyi/cp_logo_flower.svg';
  static const String opinionSecureAsset =
      'assets/citoyen_peyi/cp_illustration_opinion_secure.svg';

  CitizenPublicAccessSession? get _session =>
      initialSession ?? CitizenPublicAccessService.instance.currentSession;

  void _openConsultations(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/citizen/consultations'),
        builder: (_) => CitizenConsultationsPage(
          initialSession: _session,
          voteAccessService: voteAccessService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final openCount = session?.openPolls.length ?? 0;

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
            constraints: const BoxConstraints(maxWidth: 760),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BrandBar(
                            session: session,
                            onConsultations: () => _openConsultations(context),
                          ),
                          const SizedBox(height: 34),
                          const _WelcomeHero(),
                          const SizedBox(height: 18),
                          _ParticipationHero(
                            onPressed: () => _openConsultations(context),
                          ),
                          const SizedBox(height: 16),
                          _YellowParticipateButton(
                            onPressed: () => _openConsultations(context),
                          ),
                          const SizedBox(height: 24),
                          _NowSection(
                            count: openCount,
                            onPressed: () => _openConsultations(context),
                          ),
                          const SizedBox(height: 26),
                          const _HowItWorks(),
                          const SizedBox(height: 18),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LegalPage(),
                              ),
                            ),
                            icon: const Icon(Icons.info_outline_rounded),
                            label: const Text('À propos de Citoyen Peyi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CitizenBottomNav(
                    activeTab: CitizenNavTab.home,
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
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({required this.session, required this.onConsultations});

  final CitizenPublicAccessSession? session;
  final VoidCallback onConsultations;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              SvgPicture.asset(CitizenHomePage.flowerLogoAsset, width: 54),
              const SizedBox(width: 10),
              const Flexible(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.7,
                    ),
                    children: [
                      TextSpan(
                        text: 'Citoyen ',
                        style: TextStyle(color: CitizenDesignTokens.deepBlue),
                      ),
                      TextSpan(
                        text: 'Peyi',
                        style: TextStyle(
                          color: CitizenDesignTokens.yellowStrong,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        _HeaderAction(
          tooltip: 'Mon profil',
          icon: Icons.person_outline_rounded,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CitizenProfilePage(initialSession: session),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _NotificationAction(onPressed: onConsultations),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x22005A9C),
      borderRadius: BorderRadius.circular(20),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: CitizenDesignTokens.deepBlue),
      ),
    );
  }
}

class _NotificationAction extends StatefulWidget {
  const _NotificationAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_NotificationAction> createState() => _NotificationActionState();
}

class _NotificationActionState extends State<_NotificationAction> {
  final _service = NewPollBadgeService.instance;

  @override
  void initState() {
    super.initState();
    _service.startListening();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _service.newCount,
      builder: (context, count, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _HeaderAction(
              tooltip: 'Nouvelles consultations',
              icon: Icons.notifications_none_rounded,
              onPressed: () {
                _service.markAllSeen();
                widget.onPressed();
              },
            ),
            if (count > 0)
              Positioned(
                right: -1,
                top: -3,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: CitizenDesignTokens.yellowStrong,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: CitizenDesignTokens.deepBlue,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final illustrationWidth = compact ? 136.0 : 182.0;
        final textWidth = compact
            ? (constraints.maxWidth * 0.68).clamp(170.0, 210.0).toDouble()
            : (constraints.maxWidth * 0.62).clamp(210.0, 330.0).toDouble();
        return SizedBox(
          height: compact ? 196 : 184,
          child: Stack(
            children: [
              Positioned(
                left: 10,
                top: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour !',
                      style: TextStyle(
                        color: CitizenDesignTokens.deepBlue,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 9),
                    SizedBox(
                      width: textWidth,
                      child: Text(
                        'Merci d’agir pour votre\ncommune et votre communauté',
                        style: TextStyle(
                          color: CitizenDesignTokens.textMuted,
                          fontSize: 18,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: CitizenDesignTokens.yellowStrong,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      child: SizedBox(width: 42, height: 5),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -10,
                bottom: -4,
                child: Opacity(
                  opacity: 0.9,
                  child: SvgPicture.asset(
                    CitizenHomePage.opinionSecureAsset,
                    width: illustrationWidth,
                    height: compact ? 126 : 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ParticipationHero extends StatelessWidget {
  const _ParticipationHero({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Participer aux consultations citoyennes',
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onPressed,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(24, 24, 22, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF67C5FF), Color(0xFF168FE4)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330077C8),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                bottom: -34,
                child: Icon(
                  Icons.public_rounded,
                  size: 190,
                  color: Colors.white.withValues(alpha: 0.11),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.76),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'À VOUS LA PAROLE',
                      style: TextStyle(
                        color: CitizenDesignTokens.primaryBlue,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Participez aux\nconsultations citoyennes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: CitizenDesignTokens.yellowStrong,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Anonyme, sécurisé et confidentiel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

class _YellowParticipateButton extends StatelessWidget {
  const _YellowParticipateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: FilledButton(
        key: const ValueKey('citizenHomeParticipateButton'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: CitizenDesignTokens.yellowStrong,
          foregroundColor: CitizenDesignTokens.deepBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 5,
          shadowColor: const Color(0x55F2B600),
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                'Je participe',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: CircleAvatar(
                radius: 23,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: CitizenDesignTokens.primaryBlue,
                  size: 29,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowSection extends StatelessWidget {
  const _NowSection({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'En ce moment',
                style: TextStyle(
                  color: CitizenDesignTokens.deepBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(onPressed: onPressed, child: const Text('Voir toutes')),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          elevation: 3,
          shadowColor: const Color(0x22005A9C),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            key: const ValueKey('citizenHomeCurrentConsultations'),
            borderRadius: BorderRadius.circular(24),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 31,
                    backgroundColor: CitizenDesignTokens.skyBlue,
                    child: Icon(
                      Icons.assignment_turned_in_outlined,
                      color: CitizenDesignTokens.primaryBlue,
                      size: 31,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultations en cours',
                          style: TextStyle(
                            color: CitizenDesignTokens.deepBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Donnez votre avis sur les projets qui vous concernent.',
                          style: TextStyle(
                            color: CitizenDesignTokens.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 66,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$count',
                          style: const TextStyle(
                            color: CitizenDesignTokens.success,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'en cours',
                          style: TextStyle(
                            color: CitizenDesignTokens.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comment ça marche ?',
          style: TextStyle(
            color: CitizenDesignTokens.deepBlue,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            _Step(icon: Icons.edit_outlined, label: '1. Je participe'),
            _Step(icon: Icons.lock_outline_rounded, label: '2. C’est anonyme'),
            _Step(
              icon: Icons.bar_chart_rounded,
              label: '3. Je vois les résultats',
            ),
          ],
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: CitizenDesignTokens.skyBlue,
            child: Icon(icon, color: CitizenDesignTokens.primaryBlue, size: 29),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CitizenDesignTokens.deepBlue,
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
