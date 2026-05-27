import 'package:flutter/material.dart';

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

  static const String backgroundPath =
      'assets/images/fondecran.png';
  static const String logoPath =
      'assets/citoyen_peyi/logo_citoyen_peyi_transparent.webp';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ResponsiveHomeLayout(),
      bottomNavigationBar: PublicBottomNav(currentTab: PublicTab.home),
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
  bool get _isDesktop => layout == _HomeLayout.desktop;

  @override
  Widget build(BuildContext context) {
    final maxWidth = _isDesktop ? 520.0 : 480.0;
    final hPad = _isMobile ? 22.0 : 36.0;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            CitoyenPeyiHomePage.backgroundPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF003E82), Color(0xFF0477A8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF001E4A).withValues(alpha: 0.40),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: _isMobile ? 6 : 16),
                    const _HomeLogo(),
                    SizedBox(height: _isMobile ? 18 : 26),
                    const _MainCard(),
                    SizedBox(height: _isMobile ? 22 : 32),
                    const _AdministrationAccess(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeLogo extends StatelessWidget {
  const _HomeLogo();

  @override
  Widget build(BuildContext context) {
    final logoHeight =
        MediaQuery.textScalerOf(context).scale(130).clamp(110, 170).toDouble();
    return Semantics(
      label: 'Citoyen Peyi',
      image: true,
      child: Center(
        child: Image.asset(
          CitoyenPeyiHomePage.logoPath,
          height: logoHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ── Carte centrale transparente ─────────────────────────────────────────────

class _MainCard extends StatelessWidget {
  const _MainCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF4A9FD4).withValues(alpha: 0.55),
          width: 1.5,
        ),
        color: Colors.white.withValues(alpha: 0.07),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeroText(),
          const SizedBox(height: 26),
          _ActionCard(
            icon: Icons.group_rounded,
            title: 'Je participe',
            subtitle: 'Exprimez-vous et contribuez',
            onTap: () => Navigator.of(context).pushNamed('/participer'),
          ),
          const SizedBox(height: 18),
          _ActionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Plateforme de consultation\ncitoyenne anonyme',
            subtitle: 'Partagez vos avis en toute confidentialité',
            onTap: () => Navigator.of(context).pushNamed('/participer'),
          ),
        ],
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1565C0).withValues(alpha: 0.75),
          ),
          child: const Icon(
            Icons.star_rounded,
            color: Color(0xFFFFD740),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(
                  text: 'Votre collectivité place\n',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'votre parole',
                  style: TextStyle(color: Color(0xFFFFD740)),
                ),
                TextSpan(
                  text: ' au cœur\nde l\'action publique',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const _blue = Color(0xFF005098);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        shadowColor: Colors.black.withValues(alpha: 0.18),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 118),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8F0FE),
                  ),
                  child: Icon(icon, color: _blue, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _blue,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _blue,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Accès administration ─────────────────────────────────────────────────────

class _AdministrationAccess extends StatelessWidget {
  const _AdministrationAccess();

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(width: 14),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.35),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Accès administration',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Espace réservé aux administrateurs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
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
              _AdminChoice(
                label: 'Commune',
                icon: Icons.admin_panel_settings_rounded,
                routeName: '/admin-communal',
              ),
              _AdminChoice(
                label: 'Agent de mobilisation citoyenne',
                icon: Icons.fact_check_rounded,
                routeName: '/controleur-accueil',
              ),
              _AdminChoice(
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
  const _AdminChoice(
      {required this.label, required this.icon, required this.routeName});

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
