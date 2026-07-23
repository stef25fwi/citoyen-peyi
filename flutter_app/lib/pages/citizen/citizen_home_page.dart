import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/citizen_public_access_service.dart';
import '../../services/new_poll_badge_service.dart';
import '../../services/vote_access_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_bottom_nav.dart';
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
  static const String fullLogoAsset =
      'assets/citoyen_peyi/logo_citoyen_peyi_transparent.webp';
  static const String welcomeIllustrationAsset =
      'assets/citoyen_peyi/cp_home_welcome_people.svg';
  static const String islandWatermarkAsset =
      'assets/citoyen_peyi/cp_home_island_watermark.svg';

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

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CitizenProfilePage(initialSession: _session),
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
        backgroundColor: const Color(0xFFF8FCFF),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: _CitizenHomeContent(
                      session: session,
                      openCount: openCount,
                      onConsultations: () => _openConsultations(context),
                      onProfile: () => _openProfile(context),
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

class _CitizenHomeContent extends StatelessWidget {
  const _CitizenHomeContent({
    required this.session,
    required this.openCount,
    required this.onConsultations,
    required this.onProfile,
  });

  final CitizenPublicAccessSession? session;
  final int openCount;
  final VoidCallback onConsultations;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final narrow = constraints.maxWidth < 350;
        final horizontal = narrow ? 12.0 : compact ? 16.0 : 28.0;
        final maxContentWidth = compact ? 430.0 : 700.0;

        return SingleChildScrollView(
          key: const ValueKey('citizenHomeScroll'),
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 18),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandBar(
                    session: session,
                    compact: compact,
                    onProfile: onProfile,
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  _WelcomeSection(compact: compact, narrow: narrow),
                  SizedBox(height: compact ? 2 : 12),
                  _ParticipationHero(
                    compact: compact,
                    onPressed: onConsultations,
                  ),
                  const SizedBox(height: 12),
                  _ParticipateButton(onPressed: onConsultations),
                  SizedBox(height: compact ? 22 : 28),
                  _CurrentConsultations(
                    count: openCount,
                    onPressed: onConsultations,
                  ),
                  SizedBox(height: compact ? 20 : 28),
                  const _HowItWorks(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({
    required this.session,
    required this.compact,
    required this.onProfile,
  });

  final CitizenPublicAccessSession? session;
  final bool compact;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 58 : 72,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Mon profil',
              child: Tooltip(
                message: 'Mon profil',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onProfile,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      CitizenHomePage.fullLogoAsset,
                      width: compact ? 178 : 230,
                      height: compact ? 54 : 66,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => _LogoFallback(
                        compact: compact,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _NotificationAction(compact: compact),
        ],
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          CitizenHomePage.flowerLogoAsset,
          width: compact ? 50 : 62,
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: compact ? 23 : 30,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.8,
            ),
            children: const [
              TextSpan(
                text: 'Citoyen ',
                style: TextStyle(color: CitizenDesignTokens.deepBlue),
              ),
              TextSpan(
                text: 'Peyi',
                style: TextStyle(color: CitizenDesignTokens.yellowStrong),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final extent = compact ? 50.0 : 58.0;
    return Container(
      width: extent,
      height: extent,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: const Color(0xFFF0F4F7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12002F4A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: CitizenDesignTokens.deepBlue,
          size: compact ? 27 : 30,
        ),
      ),
    );
  }
}

class _NotificationAction extends StatefulWidget {
  const _NotificationAction({this.compact = false});

  final bool compact;

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

  Future<void> _openNotifications() async {
    unawaited(_service.check());
    final selected = await showModalBottomSheet<CitizenNotificationItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CitizenNotificationSheet(service: _service),
    );
    if (selected == null || !mounted) return;

    await _service.markSeen(selected);
    if (!mounted) return;
    Navigator.of(context).pushNamed(selected.route);
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
              compact: widget.compact,
              tooltip: 'Notifications citoyennes',
              icon: Icons.notifications_none_rounded,
              onPressed: _openNotifications,
            ),
            if (count > 0)
              Positioned(
                right: 2,
                top: 0,
                child: Semantics(
                  label: '$count nouvelle${count > 1 ? 's' : ''} notification${count > 1 ? 's' : ''}',
                  child: Container(
                    width: widget.compact ? 15 : 17,
                    height: widget.compact ? 15 : 17,
                    decoration: BoxDecoration(
                      color: CitizenDesignTokens.yellowStrong,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({required this.compact, required this.narrow});

  final bool compact;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final height = compact ? (narrow ? 178.0 : 190.0) : 270.0;
    final illustrationWidth = compact ? (narrow ? 162.0 : 202.0) : 270.0;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: compact ? -8 : 8,
            bottom: 0,
            child: IgnorePointer(
              child: SvgPicture.asset(
                CitizenHomePage.welcomeIllustrationAsset,
                width: illustrationWidth,
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? (narrow ? 200 : 258) : 410,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue !',
                      style: TextStyle(
                        color: CitizenDesignTokens.deepBlue,
                        fontSize: compact ? (narrow ? 26 : 30) : 42,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Text(
                      'Votre voix compte, participez\nà l’action publique',
                      style: TextStyle(
                        color: CitizenDesignTokens.textMuted,
                        fontSize: compact ? (narrow ? 13.5 : 15) : 21,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    Container(
                      width: compact ? 34 : 46,
                      height: compact ? 5 : 6,
                      decoration: BoxDecoration(
                        color: CitizenDesignTokens.yellowStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipationHero extends StatelessWidget {
  const _ParticipationHero({
    required this.compact,
    required this.onPressed,
  });

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 28 : 34),
        onTap: onPressed,
        child: Ink(
          height: compact ? 158 : 210,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5BC6FF), Color(0xFF168FE4)],
            ),
            borderRadius: BorderRadius.circular(compact ? 28 : 34),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F087BB9),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(compact ? 28 : 34),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SvgPicture.asset(
                      CitizenHomePage.islandWatermarkAsset,
                      width: compact ? 285 : 430,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 20 : 30,
                  compact ? 15 : 26,
                  compact ? 18 : 28,
                  compact ? 14 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 16,
                        vertical: compact ? 5 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'À VOUS LA PAROLE',
                        style: TextStyle(
                          color: CitizenDesignTokens.deepBlue,
                          fontSize: compact ? 11.5 : 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 15),
                    Text(
                      'Participez aux\nconsultations citoyennes',
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 23 : 34,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.55,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: compact ? 28 : 34,
                          height: compact ? 28 : 34,
                          decoration: const BoxDecoration(
                            color: CitizenDesignTokens.yellowStrong,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: compact ? 20 : 25,
                          ),
                        ),
                        SizedBox(width: compact ? 9 : 12),
                        Expanded(
                          child: Text(
                            'Anonyme, sécurisé et confidentiel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 13 : 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipateButton extends StatelessWidget {
  const _ParticipateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('citizenHomeParticipateButton'),
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Ink(
          height: 52,
          padding: const EdgeInsets.fromLTRB(22, 5, 7, 5),
          decoration: BoxDecoration(
            gradient: CitizenDesignTokens.actionGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2ECAA700),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 42),
              const Expanded(
                child: Text(
                  'Je participe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CitizenDesignTokens.deepBlue,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: CitizenDesignTokens.primaryBlue,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentConsultations extends StatelessWidget {
  const _CurrentConsultations({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'En ce moment',
                style: TextStyle(
                  color: CitizenDesignTokens.deepBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Voir toutes',
                style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onPressed,
            child: Container(
              height: 84,
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF0F4F7)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12002F4A),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: CitizenDesignTokens.skyBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: CitizenDesignTokens.primaryBlue,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultation en cours',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CitizenDesignTokens.deepBlue,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Donnez votre avis sur les projets\nqui vous concernent.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CitizenDesignTokens.textMuted,
                            fontSize: 12.5,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$count',
                          style: const TextStyle(
                            color: Color(0xFF169447),
                            fontSize: 23,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'en cours',
                          style: TextStyle(
                            color: Color(0xFF169447),
                            fontSize: 10.5,
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
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HowStep(
                icon: Icons.edit_outlined,
                label: '1. Je participe',
              ),
            ),
            Expanded(
              child: _HowStep(
                icon: Icons.lock_outline_rounded,
                label: '2. C’est anonyme',
              ),
            ),
            Expanded(
              child: _HowStep(
                icon: Icons.bar_chart_rounded,
                label: '3. Je vois les résultats',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: CitizenDesignTokens.skyBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: CitizenDesignTokens.primaryBlue,
            size: 29,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: CitizenDesignTokens.deepBlue,
            fontSize: 11.5,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CitizenNotificationSheet extends StatelessWidget {
  const _CitizenNotificationSheet({required this.service});

  final NewPollBadgeService service;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.76,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 10, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mes notifications',
                    style: TextStyle(
                      color: CitizenDesignTokens.deepBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await service.markAllSeen();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Tout marquer comme lu'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder<List<CitizenNotificationItem>>(
              valueListenable: service.notifications,
              builder: (context, items, _) {
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 48,
                            color: CitizenDesignTokens.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Aucune notification pour le moment',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: CitizenDesignTokens.deepBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: CitizenDesignTokens.skyBlue,
                          child: Icon(
                            _notificationIcon(item.type),
                            color: CitizenDesignTokens.primaryBlue,
                          ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(item.subtitle),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).pop(item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _notificationIcon(CitizenNotificationType type) {
    return switch (type) {
      CitizenNotificationType.consultation => Icons.how_to_vote_outlined,
      CitizenNotificationType.news => Icons.article_outlined,
      CitizenNotificationType.result => Icons.bar_chart_rounded,
    };
  }
}
