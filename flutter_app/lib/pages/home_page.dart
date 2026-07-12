import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/citoyen_theme.dart';
import '../widgets/primary_participate_button.dart';
import '../widgets/public_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CitoyenPeyiHomePage();
  }
}

class CitoyenPeyiHomePage extends StatelessWidget {
  const CitoyenPeyiHomePage({super.key});

  static const String logoPath = cpLogoPath;

  static const _statusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const _CitoyenPeyiBackground(),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: const IntrinsicHeight(
                              child: _HomeContent(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const PublicBottomNav(currentTab: PublicTab.home),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitoyenPeyiBackground extends StatelessWidget {
  const _CitoyenPeyiBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEAF8FF),
            Color(0xFF76D7FB),
            Color(0xFF1395E8),
          ],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -160,
            top: 120,
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                width: 420,
                height: 520,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(260),
                ),
              ),
            ),
          ),
          Positioned(
            right: -100,
            top: 70,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: _BackgroundDots()),
          ),
          Positioned(
            right: -24,
            bottom: 90,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                CitoyenPeyiHomePage.logoPath,
                width: 210,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDots extends StatelessWidget {
  const _BackgroundDots();

  @override
  Widget build(BuildContext context) {
    const dots = <Offset>[
      Offset(56, 84),
      Offset(82, 118),
      Offset(116, 92),
      Offset(302, 206),
      Offset(338, 240),
      Offset(886, 148),
      Offset(910, 174),
      Offset(936, 132),
      Offset(1024, 360),
      Offset(1088, 402),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return Stack(
          children: dots
              .where((dot) => dot.dx <= maxWidth + 40)
              .map(
                (dot) => Positioned(
                  left: dot.dx,
                  top: dot.dy,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final shortHeight = MediaQuery.of(context).size.height < 860;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? double.infinity : 1080,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 8 : 12,
            shortHeight ? 8 : 12,
            compact ? 8 : 12,
            shortHeight ? 4 : 6,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const _MergedLogoStatementCard(),
              SizedBox(height: shortHeight ? 6 : 10),
              const _ParticipationCard(),
              SizedBox(height: shortHeight ? 4 : 8),
              const _AdministrationAccess(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    required this.decoration,
    this.padding,
    this.constraints,
  });

  final Widget child;
  final BoxDecoration decoration;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final borderRadius = decoration.borderRadius! as BorderRadius;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: constraints,
          decoration: decoration,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _MergedLogoStatementCard extends StatelessWidget {
  const _MergedLogoStatementCard();

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final shortHeight = MediaQuery.of(context).size.height < 860;
    final titleFont = compact ? 21.0 : 40.0;
    final highlightFont = compact ? 30.0 : 54.0;
    final logoHeight = compact ? 82.0 : (shortHeight ? 130.0 : 150.0);

    return SizedBox(
      width: double.infinity,
      child: _GlassCard(
        constraints: BoxConstraints(
          minHeight: compact ? 270 : (shortHeight ? 360 : 430),
        ),
        padding: EdgeInsets.fromLTRB(
          compact ? 18 : 34,
          compact ? 18 : (shortHeight ? 22 : 30),
          compact ? 18 : 34,
          compact ? 18 : (shortHeight ? 22 : 30),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.30),
              cpBlue.withValues(alpha: 0.48),
              cpBlue.withValues(alpha: 0.62),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.65),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: cpBlueDark.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: compact ? 4 : 42,
              top: compact ? 118 : (shortHeight ? 180 : 214),
              child: Icon(
                Icons.groups_rounded,
                size: compact ? 44 : 78,
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            Positioned(
              right: compact ? 4 : 64,
              top: compact ? 116 : (shortHeight ? 178 : 212),
              child: Icon(
                Icons.account_balance_rounded,
                size: compact ? 50 : 82,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Citoyen Peyi',
                  image: true,
                  child: Image.asset(
                    CitoyenPeyiHomePage.logoPath,
                    height: logoHeight,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: compact ? 12 : 20),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: GoogleFonts.inter(
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: titleFont,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      const TextSpan(text: 'Votre collectivité place\n'),
                      TextSpan(
                        text: 'votre parole\n',
                        style: GoogleFonts.inter(
                          color: cpYellow,
                          fontSize: highlightFont,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              offset: const Offset(0, 3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const TextSpan(text: 'au cœur de l\'action publique'),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: -16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.72),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.format_quote_rounded,
                    color: cpBlueDark,
                    size: 34,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipationCard extends StatelessWidget {
  const _ParticipationCard();

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final shortHeight = MediaQuery.of(context).size.height < 860;

    return _GlassCard(
      constraints:
          BoxConstraints(minHeight: compact ? 162 : (shortHeight ? 232 : 295)),
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 22,
        compact ? 8 : (shortHeight ? 18 : 30),
        compact ? 14 : 22,
        compact ? 8 : (shortHeight ? 16 : 28),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: cpBlue.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'EXPRIMEZ VOUS',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: cpBlueDark,
              fontSize: compact ? 18 : 25,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'et CONTRIBUEZ.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: cpBlueDark,
              fontSize: compact ? 17 : 23,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 46,
            height: 3,
            decoration: BoxDecoration(
              color: cpYellowStrong,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 16),
          const PrimaryParticipateButton(),
          const SizedBox(height: 16),
          const _ConfidentialityLine(),
        ],
      ),
    );
  }
}

class _ConfidentialityLine extends StatelessWidget {
  const _ConfidentialityLine();

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: cpBlueDark,
              size: 26,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Plateforme de consultation citoyenne anonyme',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: cpBlueDark,
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Partagez vos avis en toute confidentialité',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: cpTextMuted,
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AdministrationAccess extends StatelessWidget {
  const _AdministrationAccess();

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);

    return Semantics(
      button: true,
      label: 'Accès administration',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showAdministrationSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.34),
                      thickness: 1,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: compact ? 40 : 46,
                    height: compact ? 40 : 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: cpWhite,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.34),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Accès administration',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: cpWhite,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Espace réservé aux administrateurs',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: compact ? 10.5 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdministrationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Administration',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const _AdminChoice(
                label: 'Commune',
                icon: Icons.admin_panel_settings_rounded,
                routeName: '/admin-communal',
              ),
              const _AdminChoice(
                label: 'Agent de mobilisation citoyenne',
                icon: Icons.fact_check_rounded,
                routeName: '/controleur-accueil',
              ),
              const _AdminChoice(
                label: 'Super administration',
                icon: Icons.workspace_premium_rounded,
                routeName: '/super-admin',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminChoice extends StatelessWidget {
  const _AdminChoice({
    required this.label,
    required this.icon,
    required this.routeName,
  });

  final String label;
  final IconData icon;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ListTile(
        minTileHeight: 54,
        leading: Icon(icon, color: cpBlueDark),
        title:
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(routeName);
        },
      ),
    );
  }
}
