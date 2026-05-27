import 'package:flutter/material.dart';

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
    return const Scaffold(body: ResponsiveHomeLayout());
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
    final horizontalPadding = _isMobile ? 20.0 : 40.0;
    final maxWidth = _isDesktop ? 1120.0 : 760.0;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            CitoyenPeyiHomePage.backgroundPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF004B98), Color(0xFF0477A8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(color: Colors.black26),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 20, horizontalPadding, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: _isMobile ? 8 : 18),
                    const _HomeLogo(),
                    SizedBox(height: _isMobile ? 20 : 28),
                    const _PlatformPill(),
                    SizedBox(height: _isMobile ? 26 : 36),
                    _PrimaryActions(isDesktop: _isDesktop),
                    SizedBox(height: _isMobile ? 28 : 44),
                    const _PublicNav(),
                    const SizedBox(height: 16),
                    const _AdministrationAccess(),
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
        MediaQuery.textScalerOf(context).scale(92).clamp(76, 116).toDouble();
    return Semantics(
      label: 'Citoyen Peyi',
      image: true,
      child: Image.asset(
        CitoyenPeyiHomePage.logoPath,
        height: logoHeight,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _PlatformPill extends StatelessWidget {
  const _PlatformPill();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(
            'Votre collectivité place votre parole au coeur de l\'action publique',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final citizen = Semantics(
      button: true,
      label: 'Participer à une consultation citoyenne',
      child: _HomeButton(
        label: 'Je participe',
        icon: Icons.how_to_vote_rounded,
        emphasized: true,
        onPressed: () => Navigator.of(context).pushNamed('/participer'),
      ),
    );
    final controller = Semantics(
      button: true,
      label: 'Accéder à l’espace agent de mobilisation citoyenne',
      child: _HomeButton(
        label: 'Agent de mobilisation citoyenne / accueil',
        icon: Icons.fact_check_rounded,
        onPressed: () => Navigator.of(context).pushNamed('/controleur-accueil'),
      ),
    );

    if (!isDesktop) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [citizen, const SizedBox(height: 12), controller]);
    }

    return Row(children: [
      Expanded(child: citizen),
      const SizedBox(width: 16),
      Expanded(child: controller)
    ]);
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton(
      {required this.label,
      required this.icon,
      required this.onPressed,
      this.emphasized = false});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final background =
        emphasized ? Colors.white : Colors.white.withValues(alpha: 0.08);
    final foreground = emphasized ? const Color(0xFF005098) : Colors.white;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(
              color: emphasized
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.70)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _PublicNav extends StatelessWidget {
  const _PublicNav();

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavEntry('Accueil', Icons.home_rounded, '/accueil'),
      _NavEntry('Avis', Icons.rate_review_rounded, '/avis'),
      _NavEntry('Résultats', Icons.bar_chart_rounded, '/resultats'),
      _NavEntry('Actualités', Icons.article_rounded, '/actualites'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [for (final item in items) _PublicNavButton(entry: item)],
        ),
      ),
    );
  }
}

class _NavEntry {
  const _NavEntry(this.label, this.icon, this.routeName);

  final String label;
  final IconData icon;
  final String routeName;
}

class _PublicNavButton extends StatelessWidget {
  const _PublicNavButton({required this.entry});

  final _NavEntry entry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: entry.label,
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(entry.routeName),
        icon: Icon(entry.icon, size: 20),
        label: Text(entry.label),
        style: TextButton.styleFrom(
            minimumSize: const Size(116, 44),
            foregroundColor: const Color(0xFF005098)),
      ),
    );
  }
}

class _AdministrationAccess extends StatelessWidget {
  const _AdministrationAccess();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Accès administration',
      child: TextButton.icon(
        onPressed: () => _showAdministrationSheet(context),
        icon: const Icon(Icons.lock_outline_rounded, size: 18),
        label: const Text('Accès administration'),
        style: TextButton.styleFrom(
            foregroundColor: Colors.white, minimumSize: const Size(180, 44)),
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
              Text('Administration',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _AdminChoice(
                  label: 'Commune',
                  icon: Icons.admin_panel_settings_rounded,
                  routeName: '/admin-communal'),
              _AdminChoice(
                  label: 'Agent de mobilisation citoyenne',
                  icon: Icons.fact_check_rounded,
                  routeName: '/controleur-accueil'),
              _AdminChoice(
                  label: 'Super administration',
                  icon: Icons.workspace_premium_rounded,
                  routeName: '/super-admin'),
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
