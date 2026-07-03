import 'package:flutter/material.dart';

import '../widgets/public_bottom_nav.dart';
import 'access_citizen_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CitoyenPeyiHomePage();
  }
}

class CitoyenPeyiHomePage extends StatelessWidget {
  const CitoyenPeyiHomePage({super.key});

  static const String logoPath =
      'assets/citoyen_peyi/logo_citoyen_peyi_transparent.webp';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ResponsiveHomeLayout(),
      bottomNavigationBar: PublicBottomNav(
        currentTab: PublicTab.home,
        backgroundColor: Color(0xFFEAF7FF),
        indicatorColor: Color(0xFFCAE9FB),
      ),
    );
  }
}

class ResponsiveHomeLayout extends StatelessWidget {
  const ResponsiveHomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const _HomeScaffold(layout: _HomeLayout.mobile);
        }
        if (constraints.maxWidth < 1024) {
          return const _HomeScaffold(layout: _HomeLayout.tablet);
        }
        return const _HomeScaffold(layout: _HomeLayout.desktop);
      },
    );
  }
}

enum _HomeLayout { mobile, tablet, desktop }

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({required this.layout});

  final _HomeLayout layout;

  bool get _isMobile => layout == _HomeLayout.mobile;

  @override
  Widget build(BuildContext context) {
    final maxWidth = switch (layout) {
      _HomeLayout.mobile => 480.0,
      _HomeLayout.tablet => 720.0,
      _HomeLayout.desktop => 920.0,
    };
    const hPad = 6.0;
    final vPad = switch (layout) {
      _HomeLayout.mobile => 12.0,
      _HomeLayout.tablet => 18.0,
      _HomeLayout.desktop => 24.0,
    };

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF031633), Color(0xFF0B2F5B), Color(0xFF123F78)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final content = _HomeContent(
                layout: layout,
                maxWidth: maxWidth,
                horizontalPadding: hPad,
                verticalPadding: vPad,
                pinAdministrationToBottom: _isMobile,
              );

              if (_isMobile) {
                return SizedBox(
                  width: viewport.maxWidth,
                  height: viewport.maxHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: viewport.maxWidth,
                      height: viewport.maxHeight,
                      child: content,
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: content,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.layout,
    required this.maxWidth,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.pinAdministrationToBottom,
  });

  final _HomeLayout layout;
  final double maxWidth;
  final double horizontalPadding;
  final double verticalPadding;
  final bool pinAdministrationToBottom;

  bool get _isMobile => layout == _HomeLayout.mobile;
  bool get _isDesktop => layout == _HomeLayout.desktop;

  @override
  Widget build(BuildContext context) {
    final topPadding = switch (layout) {
      _HomeLayout.mobile => 0.0,
      _HomeLayout.tablet => 6.0,
      _HomeLayout.desktop => 8.0,
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        verticalPadding,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize:
                pinAdministrationToBottom ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MainCard(layout: layout),
              SizedBox(height: _isMobile ? 16 : (_isDesktop ? 24 : 20)),
              if (pinAdministrationToBottom) const Spacer(),
              _AdministrationAccess(layout: layout),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLogo extends StatelessWidget {
  const _HomeLogo({required this.layout});

  final _HomeLayout layout;

  @override
  Widget build(BuildContext context) {
    final targetHeight = switch (layout) {
      _HomeLayout.mobile => 198.0,
      _HomeLayout.tablet => 279.0,
      _HomeLayout.desktop => 310.5,
    };
    final minHeight = switch (layout) {
      _HomeLayout.mobile => 171.0,
      _HomeLayout.tablet => 252.0,
      _HomeLayout.desktop => 274.5,
    };
    final maxHeight = switch (layout) {
      _HomeLayout.mobile => 216.0,
      _HomeLayout.tablet => 319.5,
      _HomeLayout.desktop => 351.0,
    };
    final verticalPadding = switch (layout) {
      _HomeLayout.mobile => 0.0,
      _HomeLayout.tablet => 11.0,
      _HomeLayout.desktop => 12.0,
    };
    final logoHeight = MediaQuery.textScalerOf(context)
        .scale(targetHeight)
        .clamp(minHeight, maxHeight)
        .toDouble();

    return Semantics(
      label: 'Citoyen Peyi',
      image: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Center(
          child: Image.asset(
            CitoyenPeyiHomePage.logoPath,
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _MainCard extends StatelessWidget {
  const _MainCard({required this.layout});

  final _HomeLayout layout;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = switch (layout) {
      _HomeLayout.mobile => 8.0,
      _HomeLayout.tablet => 28.0,
      _HomeLayout.desktop => 32.0,
    };
    final verticalPadding = switch (layout) {
      _HomeLayout.mobile => 12.0,
      _HomeLayout.tablet => 20.0,
      _HomeLayout.desktop => 24.0,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF8FB4E8),
          width: 1.5,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFF113A70), Color(0xFF0A274D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33010B19),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HomeLogo(layout: layout),
          SizedBox(height: layout == _HomeLayout.mobile ? 16 : 20),
          _HeroText(layout: layout),
          SizedBox(height: layout == _HomeLayout.mobile ? 52 : 60),
          _ActionCards(layout: layout),
        ],
      ),
    );
  }
}

class _ActionCards extends StatelessWidget {
  const _ActionCards({required this.layout});

  final _HomeLayout layout;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.group_rounded,
      title: 'Je participe',
      subtitle: 'Exprimez-vous et contribuez',
      secondaryIcon: Icons.chat_bubble_outline_rounded,
      secondaryTitle: 'Plateforme de consultation citoyenne anonyme',
      secondarySubtitle: 'Partagez vos avis en toute confidentialité',
      layout: layout,
      onTap: () => Navigator.of(context).pushNamed(AccessCitizenPage.routeName),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.layout});

  final _HomeLayout layout;

  @override
  Widget build(BuildContext context) {
    final fontSize = switch (layout) {
      _HomeLayout.mobile => 17.0,
      _HomeLayout.tablet => 27.0,
      _HomeLayout.desktop => 30.0,
    };
    final textSpans = layout == _HomeLayout.mobile
        ? const [
            TextSpan(
              text: 'Votre collectivité place ',
              style: TextStyle(color: Color(0xFFE6EEF9)),
            ),
            TextSpan(
              text: 'votre parole\n',
              style: TextStyle(color: Color(0xFFBFD8FF)),
            ),
            TextSpan(
              text: 'au cœur de l\'action publique',
              style: TextStyle(color: Color(0xFFE6EEF9)),
            ),
          ]
        : const [
            TextSpan(
              text: 'Votre collectivité place ',
              style: TextStyle(color: Color(0xFFE6EEF9)),
            ),
            TextSpan(
              text: 'votre parole',
              style: TextStyle(color: Color(0xFFBFD8FF)),
            ),
            TextSpan(
              text: ' au cœur de l\'action publique',
              style: TextStyle(color: Color(0xFFE6EEF9)),
            ),
          ];

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: layout == _HomeLayout.mobile ? 1.18 : 1.22,
          letterSpacing: 0,
        ),
        children: textSpans,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.layout,
    required this.onTap,
    this.secondaryIcon,
    this.secondaryTitle,
    this.secondarySubtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _HomeLayout layout;
  final VoidCallback onTap;
  final IconData? secondaryIcon;
  final String? secondaryTitle;
  final String? secondarySubtitle;

  static const _blue = Color(0xFF005098);

  bool get _hasSecondaryContent =>
      secondaryTitle != null && secondarySubtitle != null;

  @override
  Widget build(BuildContext context) {
    final minHeight = switch (layout) {
      _HomeLayout.mobile => _hasSecondaryContent ? 184.0 : 64.0,
      _HomeLayout.tablet => _hasSecondaryContent ? 220.0 : 92.0,
      _HomeLayout.desktop => _hasSecondaryContent ? 244.0 : 116.0,
    };
    final horizontalPadding = switch (layout) {
      _HomeLayout.mobile => 8.0,
      _HomeLayout.tablet => 14.0,
      _HomeLayout.desktop => 16.0,
    };
    final verticalPadding = switch (layout) {
      _HomeLayout.mobile => 8.0,
      _HomeLayout.tablet => 12.0,
      _HomeLayout.desktop => 14.0,
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      shadowColor: Colors.black.withValues(alpha: 0.18),
      elevation: 4,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: _hasSecondaryContent ? _mergedContent(context) : _decoratedContent(),
      ),
    );
  }

  Widget _mergedContent(BuildContext context) {
    final gap = layout == _HomeLayout.mobile ? 10.0 : 14.0;
    final buttonHeight = layout == _HomeLayout.mobile ? 38.0 : 42.0;
    final buttonWidth = layout == _HomeLayout.mobile ? 196.0 : 224.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _actionRow(
          title: title,
          subtitle: subtitle,
        ),
        SizedBox(height: gap),
        Stack(
          alignment: Alignment.center,
          children: [
            Divider(
              color: const Color(0xFF77BFE4).withValues(alpha: 0.55),
              thickness: 1,
            ),
            SizedBox(
              height: buttonHeight,
              width: buttonWidth,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B2F5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: const BorderSide(color: Color(0xFFBFD8FF)),
                  ),
                  textStyle: TextStyle(
                    fontSize: layout == _HomeLayout.mobile ? 12.0 : 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Connexion citoyenne'),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _actionRow(
          title: secondaryTitle!,
          subtitle: secondarySubtitle!,
        ),
      ],
    );
  }

  Widget _decoratedContent() {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: _actionRow(
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  Widget _actionRow({
    required String title,
    required String subtitle,
  }) {
    final titleSize = switch (layout) {
      _HomeLayout.mobile => 14.0,
      _HomeLayout.tablet => 16.0,
      _HomeLayout.desktop => 17.0,
    };
    final subtitleSize = layout == _HomeLayout.mobile ? 11.0 : 13.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _blue,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              SizedBox(height: layout == _HomeLayout.mobile ? 2 : 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF52627A),
                  fontSize: subtitleSize,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdministrationAccess extends StatelessWidget {
  const _AdministrationAccess({required this.layout});

  final _HomeLayout layout;

  @override
  Widget build(BuildContext context) {
    final iconSize = layout == _HomeLayout.mobile ? 38.0 : 46.0;
    final iconGlyphSize = layout == _HomeLayout.mobile ? 19.0 : 22.0;
    final sideGap = layout == _HomeLayout.mobile ? 10.0 : 14.0;
    final titleSize = layout == _HomeLayout.mobile ? 12.0 : 14.0;
    final subtitleSize = layout == _HomeLayout.mobile ? 10.5 : 12.0;

    return Semantics(
      button: true,
      label: 'Accès administration',
      child: GestureDetector(
        onTap: () => _showAdministrationSheet(context),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.35),
                    thickness: 1,
                  ),
                ),
                SizedBox(width: sideGap),
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: iconGlyphSize,
                  ),
                ),
                SizedBox(width: sideGap),
                Expanded(
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.35),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: layout == _HomeLayout.mobile ? 4 : 7),
            Text(
              'Accès administration',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: layout == _HomeLayout.mobile ? 1 : 2),
            Text(
              'Espace réservé aux administrateurs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: subtitleSize,
              ),
            ),
          ],
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
        leading: Icon(icon, color: const Color(0xFF005098)),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(routeName);
        },
      ),
    );
  }
}
