import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Status bar transparente pour laisser voir le fond de la page d'accueil.
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
        body: const ResponsiveHomeLayout(),
        bottomNavigationBar: PublicBottomNav(
          currentTab: PublicTab.home,
          backgroundColor: const Color(0xFFEAF7FF),
          indicatorColor: const Color(0xFFCAE9FB),
        ),
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
      _HomeLayout.mobile => 6.0,
      _HomeLayout.tablet => 12.0,
      _HomeLayout.desktop => 16.0,
    };

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9BE4FF), Color(0xFF44B7FF), Color(0xFF167DDB)],
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
      _HomeLayout.tablet => 4.0,
      _HomeLayout.desktop => 6.0,
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
              _TransparentHeader(layout: layout),
              SizedBox(height: _isMobile ? 6 : (_isDesktop ? 16 : 12)),
              _HeroCard(layout: layout),
              if (pinAdministrationToBottom)
                const Spacer()
              else
                SizedBox(height: _isMobile ? 8 : (_isDesktop ? 18 : 12)),
              _MainCard(layout: layout),
              if (pinAdministrationToBottom)
                const Spacer()
              else
                SizedBox(height: _isMobile ? 16 : (_isDesktop ? 24 : 20)),
              _AdministrationAccess(layout: layout),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLogo extends StatelessWidget {
  const _HomeLogo({required this.layout, this.heightFactor = 1});

  final _HomeLayout layout;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final targetHeight = switch (layout) {
      _HomeLayout.mobile => 267.0,
      _HomeLayout.tablet => 377.0,
      _HomeLayout.desktop => 419.0,
    };
    final minHeight = switch (layout) {
      _HomeLayout.mobile => 231.0,
      _HomeLayout.tablet => 340.0,
      _HomeLayout.desktop => 371.0,
    };
    final maxHeight = switch (layout) {
      _HomeLayout.mobile => 292.0,
      _HomeLayout.tablet => 431.0,
      _HomeLayout.desktop => 474.0,
    };
    final verticalPadding = switch (layout) {
      _HomeLayout.mobile => 0.0,
      _HomeLayout.tablet => 11.0,
      _HomeLayout.desktop => 12.0,
    };
    final logoHeight = (MediaQuery.textScalerOf(context)
          .scale(targetHeight)
          .clamp(minHeight, maxHeight) *
        heightFactor)
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

class _TransparentHeader extends StatelessWidget {
  const _TransparentHeader({required this.layout});

  final _HomeLayout layout;

  @override
  Widget build(BuildContext context) {
    final padding = switch (layout) {
      _HomeLayout.mobile => const EdgeInsets.fromLTRB(8, 0, 8, 0),
      _HomeLayout.tablet => const EdgeInsets.fromLTRB(14, 0, 14, 0),
      _HomeLayout.desktop => const EdgeInsets.fromLTRB(20, 0, 20, 0),
    };
    final heightFactor = switch (layout) {
      _HomeLayout.mobile => 0.50,
      _HomeLayout.tablet => 0.60,
      _HomeLayout.desktop => 0.65,
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: _HomeLogo(layout: layout, heightFactor: heightFactor),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.layout});

  final _HomeLayout layout;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = switch (layout) {
      _HomeLayout.mobile => 12.0,
      _HomeLayout.tablet => 24.0,
      _HomeLayout.desktop => 30.0,
    };
    final verticalPadding = switch (layout) {
      _HomeLayout.mobile => 10.0,
      _HomeLayout.tablet => 18.0,
      _HomeLayout.desktop => 22.0,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180A3566),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: _HeroText(layout: layout),
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
      _HomeLayout.tablet => 20.0,
      _HomeLayout.desktop => 24.0,
    };
    final topPad = switch (layout) {
      _HomeLayout.mobile => 10.0,
      _HomeLayout.tablet => 14.0,
      _HomeLayout.desktop => 16.0,
    };
    final bottomPad = switch (layout) {
      _HomeLayout.mobile => 12.0,
      _HomeLayout.tablet => 20.0,
      _HomeLayout.desktop => 24.0,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF7FCBFF),
          width: 1.5,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFF5BD1FF), Color(0xFF168DE3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2D0A3566),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPad,
        horizontalPadding,
        bottomPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
      _HomeLayout.mobile => 21.0,
      _HomeLayout.tablet => 33.0,
      _HomeLayout.desktop => 38.0,
    };
    // 'votre parole' plus grand que le reste pour un impact visuel fort, et
    // isole entre deux retours a la ligne forces pour ne JAMAIS etre coupe
    // entre 'votre' et 'parole' par le retour a la ligne automatique.
    final highlightFontSize = fontSize + (layout == _HomeLayout.mobile ? 6.0 : 10.0);
    final textSpans = [
      const TextSpan(
        text: 'Votre collectivité place\n',
        style: TextStyle(color: Color(0xFFE6EEF9)),
      ),
      TextSpan(
        text: 'votre parole\n',
        style: TextStyle(
          color: const Color(0xFFFFE36E),
          fontWeight: FontWeight.w900,
          fontSize: highlightFontSize,
          letterSpacing: 0.2,
        ),
      ),
      const TextSpan(
        text: 'au cœur de l\'action publique',
        style: TextStyle(color: Color(0xFFE6EEF9)),
      ),
    ];

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: layout == _HomeLayout.mobile ? 1.16 : 1.22,
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
      _HomeLayout.mobile => _hasSecondaryContent ? 208.0 : 64.0,
      _HomeLayout.tablet => _hasSecondaryContent ? 264.0 : 92.0,
      _HomeLayout.desktop => _hasSecondaryContent ? 288.0 : 116.0,
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
    final gap = layout == _HomeLayout.mobile ? 6.0 : 14.0;
    final buttonHeight = layout == _HomeLayout.mobile ? 108.0 : 120.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buttonLeadText(),
        SizedBox(height: gap),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33003366),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x55215A8A),
                blurRadius: 0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SizedBox(
            height: buttonHeight,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFE36E),
                foregroundColor: const Color(0xFF005098),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: TextStyle(
                  fontSize: layout == _HomeLayout.mobile ? 34.0 : 38.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Je participe'),
            ),
          ),
        ),
        SizedBox(height: gap),
        _actionRow(
          title: secondaryTitle!,
          subtitle: secondarySubtitle!,
        ),
      ],
    );
  }

  Widget _buttonLeadText() {
    final sharedSize = layout == _HomeLayout.mobile ? 22.0 : 24.0;

    return Column(
      children: [
        Text(
          'EXPRIMEZ VOUS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _blue,
            fontSize: sharedSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'et CONTRIBUEZ.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _blue,
            fontSize: sharedSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
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
