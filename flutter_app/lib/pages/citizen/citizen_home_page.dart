import 'dart:async';

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final smartphone = constraints.maxWidth < 600;
                  return Column(
                    children: [
                      Expanded(
                        child: smartphone
                            ? _CompactCitizenHome(
                                session: session,
                                openCount: openCount,
                                onConsultations: () =>
                                    _openConsultations(context),
                              )
                            : _ScrollableCitizenHome(
                                session: session,
                                openCount: openCount,
                                onConsultations: () =>
                                    _openConsultations(context),
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactCitizenHome extends StatelessWidget {
  const _CompactCitizenHome({
    required this.session,
    required this.openCount,
    required this.onConsultations,
  });

  final CitizenPublicAccessSession? session;
  final int openCount;
  final VoidCallback onConsultations;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dense = constraints.maxHeight < 520;
        final side = constraints.maxWidth < 350 ? 12.0 : 16.0;
        final gap = dense ? 5.0 : 8.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(side, dense ? 6 : 10, side, 4),
          child: Column(
            children: [
              _BrandBar(
                session: session,
                compact: true,
              ),
              SizedBox(height: gap),
              _CompactWelcome(dense: dense),
              SizedBox(height: gap),
              Expanded(
                child: _CompactParticipationCard(
                  dense: dense,
                  onPressed: onConsultations,
                ),
              ),
              SizedBox(height: gap),
              SizedBox(
                height: dense ? 58 : 68,
                child: Row(
                  children: [
                    Expanded(
                      child: _CompactInfoCard(
                        icon: Icons.assignment_turned_in_outlined,
                        value: '$openCount',
                        label: 'en cours',
                        onTap: onConsultations,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: _CompactInfoCard(
                        icon: Icons.verified_user_outlined,
                        value: '3 étapes',
                        label: 'Comment ça marche ?',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: dense ? 1 : 3),
              SizedBox(
                height: dense ? 28 : 32,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LegalPage()),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 17),
                  label: const Text(
                    'À propos de Citoyen Peyi',
                    style: TextStyle(fontSize: 12.5),
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

class _ScrollableCitizenHome extends StatelessWidget {
  const _ScrollableCitizenHome({
    required this.session,
    required this.openCount,
    required this.onConsultations,
  });

  final CitizenPublicAccessSession? session;
  final int openCount;
  final VoidCallback onConsultations;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandBar(session: session),
          const SizedBox(height: 24),
          const _WideWelcome(),
          const SizedBox(height: 18),
          _WideParticipationCard(onPressed: onConsultations),
          const SizedBox(height: 16),
          _WideParticipateButton(onPressed: onConsultations),
          const SizedBox(height: 22),
          _WideCurrentSection(count: openCount, onPressed: onConsultations),
          const SizedBox(height: 24),
          const _WideHowItWorks(),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LegalPage()),
            ),
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text('À propos de Citoyen Peyi'),
          ),
        ],
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({required this.session, this.compact = false});

  final CitizenPublicAccessSession? session;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 38.0 : 52.0;
    return SizedBox(
      height: compact ? 44 : 56,
      child: Row(
        children: [
          SvgPicture.asset(CitizenHomePage.flowerLogoAsset, width: logoSize),
          SizedBox(width: compact ? 7 : 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: compact ? 20 : 25,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.6,
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _HeaderAction(
            compact: compact,
            tooltip: 'Mon profil',
            icon: Icons.person_outline_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CitizenProfilePage(initialSession: session),
              ),
            ),
          ),
          SizedBox(width: compact ? 5 : 8),
          _NotificationAction(compact: compact),
        ],
      ),
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
    return Material(
      color: Colors.white,
      elevation: compact ? 1 : 3,
      shadowColor: const Color(0x22005A9C),
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: compact ? 38 : 44,
        height: compact ? 38 : 44,
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: CitizenDesignTokens.deepBlue,
            size: compact ? 21 : 24,
          ),
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
                right: -2,
                top: -4,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: CitizenDesignTokens.yellowStrong,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
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

class _CompactWelcome extends StatelessWidget {
  const _CompactWelcome({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: dense ? 46 : 60,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 5 : 6),
      decoration: BoxDecoration(
        color: CitizenDesignTokens.lightBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.waving_hand_rounded,
              color: CitizenDesignTokens.yellowStrong,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour !',
                  style: TextStyle(
                    color: CitizenDesignTokens.deepBlue,
                    fontSize: dense ? 16 : 18,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!dense)
                  const Text(
                    'Votre avis compte pour votre commune.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CitizenDesignTokens.textMuted,
                      fontSize: 11.5,
                      height: 1,
                      fontWeight: FontWeight.w600,
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

class _CompactParticipationCard extends StatelessWidget {
  const _CompactParticipationCard({
    required this.dense,
    required this.onPressed,
  });

  final bool dense;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('citizenHomeParticipateButton'),
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(dense ? 14 : 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF67C5FF), Color(0xFF168FE4)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'À VOUS LA PAROLE',
                      style: TextStyle(
                        color: CitizenDesignTokens.deepBlue,
                        fontSize: dense ? 11 : 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: dense ? 4 : 7),
                    Text(
                      'Participez aux consultations citoyennes',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: dense ? 18 : 21,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: dense ? 5 : 9),
                    const Text(
                      'Anonyme, sécurisé et confidentiel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: dense ? 7 : 11),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: dense ? 13 : 16,
                        vertical: dense ? 7 : 9,
                      ),
                      decoration: BoxDecoration(
                        color: CitizenDesignTokens.yellowStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Je participe',
                        style: TextStyle(
                          color: CitizenDesignTokens.deepBlue,
                          fontSize: dense ? 14 : 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.how_to_vote_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: dense ? 54 : 66,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactInfoCard extends StatelessWidget {
  const _CompactInfoCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(icon, color: CitizenDesignTokens.primaryBlue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CitizenDesignTokens.deepBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CitizenDesignTokens.textMuted,
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
    );
  }
}

class _WideWelcome extends StatelessWidget {
  const _WideWelcome();

  @override
  Widget build(BuildContext context) {
    return const Column(
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
        SizedBox(height: 6),
        Text(
          'Merci d’agir pour votre commune et votre communauté.',
          style: TextStyle(
            color: CitizenDesignTokens.textMuted,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _WideParticipationCard extends StatelessWidget {
  const _WideParticipationCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onPressed,
      child: Ink(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF67C5FF), Color(0xFF168FE4)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À VOUS LA PAROLE',
                    style: TextStyle(
                      color: CitizenDesignTokens.deepBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Participez aux consultations citoyennes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Anonyme, sécurisé et confidentiel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 92),
          ],
        ),
      ),
    );
  }
}

class _WideParticipateButton extends StatelessWidget {
  const _WideParticipateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: FilledButton(
        key: const ValueKey('citizenHomeParticipateButtonWide'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: CitizenDesignTokens.yellowStrong,
          foregroundColor: CitizenDesignTokens.deepBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: const Text(
          'Je participe',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _WideCurrentSection extends StatelessWidget {
  const _WideCurrentSection({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onPressed,
        leading: const CircleAvatar(
          backgroundColor: CitizenDesignTokens.skyBlue,
          child: Icon(
            Icons.assignment_turned_in_outlined,
            color: CitizenDesignTokens.primaryBlue,
          ),
        ),
        title: const Text(
          'Consultations en cours',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: const Text('Donnez votre avis sur les projets en cours.'),
        trailing: Chip(label: Text('$count en cours')),
      ),
    );
  }
}

class _WideHowItWorks extends StatelessWidget {
  const _WideHowItWorks();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
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
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _WideStep(
                        icon: Icons.edit_outlined, label: '1. Je participe')),
                Expanded(
                    child: _WideStep(
                        icon: Icons.lock_outline_rounded,
                        label: '2. C’est anonyme')),
                Expanded(
                    child: _WideStep(
                        icon: Icons.bar_chart_rounded,
                        label: '3. Je vois les résultats')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WideStep extends StatelessWidget {
  const _WideStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: CitizenDesignTokens.skyBlue,
          child: Icon(icon, color: CitizenDesignTokens.primaryBlue),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: CitizenDesignTokens.deepBlue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
