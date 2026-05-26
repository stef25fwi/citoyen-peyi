import 'dart:math';

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

  static const double designWidth = 1448;
  static const double designHeight = 1086;

  static const String backgroundPath = 'assets/citoyen_peyi/home_background.webp';
  static const String logoPath = 'assets/citoyen_peyi/logo_citoyen_peyi_transparent.webp';
  static const String adminIconPath = 'assets/citoyen_peyi/icon_admin.webp';
  static const String controllerIconPath = 'assets/citoyen_peyi/icon_controller.webp';
  static const String citizenIconPath = 'assets/citoyen_peyi/icon_citizen.webp';
  static const String superAdminIconPath = 'assets/citoyen_peyi/icon_super_admin.webp';
  static const String navHomePath = 'assets/citoyen_peyi/nav_home.webp';
  static const String navOpinionPath = 'assets/citoyen_peyi/nav_opinion.webp';
  static const String navResultsPath = 'assets/citoyen_peyi/nav_results.webp';
  static const String navNewsPath = 'assets/citoyen_peyi/nav_news.webp';
  static const String navProfilePath = 'assets/citoyen_peyi/nav_profile.webp';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = min(
            constraints.maxWidth / designWidth,
            constraints.maxHeight / designHeight,
          );

          return Center(
            child: SizedBox(
              width: designWidth * scale,
              height: designHeight * scale,
              child: Stack(
                children: [
                  _HomeBackground(scale: scale),
                  _HomeLogo(scale: scale),
                  _TopPill(scale: scale),
                  _YellowStatementBox(scale: scale),
                  _MainButtons(scale: scale),
                  _SuperAdminButton(scale: scale),
                  _BottomNavigation(scale: scale),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 900 * scale,
      child: Image.asset(
        CitoyenPeyiHomePage.backgroundPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF003F91),
                Color(0xFF002F7A),
                Color(0xFF005DA8),
                Color(0xFF0078B7),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: CustomPaint(painter: _BackgroundCirclePainter()),
        ),
      ),
    );
  }
}

class _BackgroundCirclePainter extends CustomPainter {
  const _BackgroundCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white.withValues(alpha: 0.07);
    final faint = Paint()..color = Colors.white.withValues(alpha: 0.045);
    canvas.drawCircle(Offset(size.width * 0.14, size.height * 0.20), size.width * 0.09, white);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.30), size.width * 0.11, white);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.74), size.width * 0.14, faint);
    canvas.drawCircle(Offset(size.width * 0.33, size.height * 0.58), size.width * 0.06, faint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeLogo extends StatelessWidget {
  const _HomeLogo({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 90 * scale,
      left: ((CitoyenPeyiHomePage.designWidth - 500) / 2) * scale,
      child: Image.asset(
        CitoyenPeyiHomePage.logoPath,
        width: 500 * scale,
        height: 120 * scale,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/logo1.webp',
          width: 500 * scale,
          height: 120 * scale,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 222 * scale,
      left: ((CitoyenPeyiHomePage.designWidth - 535) / 2) * scale,
      child: Container(
        width: 535 * scale,
        height: 60 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(30 * scale),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1 * scale,
          ),
        ),
        child: Text(
          'Plateforme de consultation citoyenne anonyme',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22 * scale,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _YellowStatementBox extends StatelessWidget {
  const _YellowStatementBox({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 288 * scale,
          top: 337 * scale,
          child: Icon(
            Icons.star,
            color: const Color(0xFFF4D000),
            size: 54 * scale,
          ),
        ),
        Positioned(
          left: 315 * scale,
          top: 352 * scale,
          child: Container(
            width: 790 * scale,
            height: 154 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: const Color(0xFFF4D000),
                width: 2 * scale,
              ),
            ),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 31 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: Colors.white,
                ),
                children: const [
                  TextSpan(text: 'Votre collectivité place '),
                  TextSpan(
                    text: 'votre parole au cœur\n',
                    style: TextStyle(color: Color(0xFFF4D000)),
                  ),
                  TextSpan(
                    text: 'de l’action publique',
                    style: TextStyle(color: Color(0xFFF4D000)),
                  ),
                  TextSpan(text: ' :'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MainButtons extends StatelessWidget {
  const _MainButtons({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 230 * scale,
          top: 590 * scale,
          child: CitizenHomeActionButton(
            label: 'Administrateur communal',
            iconPath: CitoyenPeyiHomePage.adminIconPath,
            fallbackIcon: Icons.admin_panel_settings_rounded,
            width: 330 * scale,
            height: 88 * scale,
            backgroundColor: Colors.white,
            borderColor: Colors.white,
            textColor: const Color(0xFF005098),
            iconColor: const Color(0xFF005098),
            fontSize: 20 * scale,
            radius: 16 * scale,
            borderWidth: 1 * scale,
            horizontalPadding: 24 * scale,
            gap: 16 * scale,
            onPressed: () => Navigator.of(context).pushNamed('/admin-communal'),
          ),
        ),
        Positioned(
          left: 594 * scale,
          top: 590 * scale,
          child: CitizenHomeActionButton(
            label: 'Contrôleur / accueil',
            iconPath: CitoyenPeyiHomePage.controllerIconPath,
            fallbackIcon: Icons.fact_check_rounded,
            width: 288 * scale,
            height: 88 * scale,
            backgroundColor: Colors.transparent,
            borderColor: Colors.white.withValues(alpha: 0.80),
            textColor: Colors.white,
            iconColor: Colors.white,
            fontSize: 20 * scale,
            fontWeight: FontWeight.w600,
            radius: 16 * scale,
            borderWidth: 1 * scale,
            horizontalPadding: 20 * scale,
            gap: 14 * scale,
            onPressed: () => Navigator.of(context).pushNamed('/controleur-accueil'),
          ),
        ),
        Positioned(
          left: 914 * scale,
          top: 590 * scale,
          child: CitizenHomeActionButton(
            label: 'Je participe',
            iconPath: CitoyenPeyiHomePage.citizenIconPath,
            fallbackIcon: Icons.how_to_vote_rounded,
            width: 268 * scale,
            height: 88 * scale,
            backgroundColor: Colors.transparent,
            borderColor: Colors.white.withValues(alpha: 0.80),
            textColor: Colors.white,
            iconColor: Colors.white,
            fontSize: 22 * scale,
            radius: 16 * scale,
            borderWidth: 1 * scale,
            horizontalPadding: 20 * scale,
            gap: 14 * scale,
            onPressed: () => Navigator.of(context).pushNamed('/participer'),
          ),
        ),
      ],
    );
  }
}

class _SuperAdminButton extends StatelessWidget {
  const _SuperAdminButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 710 * scale,
      left: ((CitoyenPeyiHomePage.designWidth - 360) / 2) * scale,
      child: CitizenHomeActionButton(
        label: 'Super administrateur',
        iconPath: CitoyenPeyiHomePage.superAdminIconPath,
        fallbackIcon: Icons.workspace_premium_rounded,
        width: 360 * scale,
        height: 78 * scale,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        borderColor: const Color(0xFFF4D000),
        textColor: Colors.white,
        iconColor: const Color(0xFFF4D000),
        fontSize: 20 * scale,
        radius: 16 * scale,
        borderWidth: 2 * scale,
        horizontalPadding: 24 * scale,
        gap: 16 * scale,
        onPressed: () => Navigator.of(context).pushNamed('/super-admin'),
      ),
    );
  }
}

class CitizenHomeActionButton extends StatelessWidget {
  const CitizenHomeActionButton({
    super.key,
    required this.label,
    required this.iconPath,
    required this.fallbackIcon,
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.fontSize,
    required this.radius,
    required this.borderWidth,
    required this.horizontalPadding,
    required this.gap,
    this.fontWeight = FontWeight.w700,
    this.onPressed,
  });

  final String label;
  final String iconPath;
  final IconData fallbackIcon;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final double fontSize;
  final double radius;
  final double borderWidth;
  final double horizontalPadding;
  final double gap;
  final FontWeight fontWeight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconSize = min(30.0, height * 0.40);

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AssetOrIcon(
                  path: iconPath,
                  fallbackIcon: fallbackIcon,
                  color: iconColor,
                  size: iconSize,
                ),
                SizedBox(width: gap),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                      color: textColor,
                    ),
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

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 900 * scale,
      left: 0,
      right: 0,
      height: 186 * scale,
      child: Container(
        color: const Color(0xFFF7F7F9),
        child: Stack(
          children: [
            _NavItem(
              scale: scale,
              centerX: 136,
              label: 'Accueil',
              iconPath: CitoyenPeyiHomePage.navHomePath,
              fallbackIcon: Icons.home_rounded,
              isActive: true,
              routeName: '/accueil',
            ),
            _NavItem(
              scale: scale,
              centerX: 424,
              label: 'Donner mon avis',
              iconPath: CitoyenPeyiHomePage.navOpinionPath,
              fallbackIcon: Icons.rate_review_rounded,
              routeName: '/avis',
            ),
            _NavItem(
              scale: scale,
              centerX: 724,
              label: 'Résultats',
              iconPath: CitoyenPeyiHomePage.navResultsPath,
              fallbackIcon: Icons.bar_chart_rounded,
              routeName: '/resultats',
            ),
            _NavItem(
              scale: scale,
              centerX: 1010,
              label: 'Actualités',
              iconPath: CitoyenPeyiHomePage.navNewsPath,
              fallbackIcon: Icons.article_rounded,
              routeName: '/actualites',
            ),
            _NavItem(
              scale: scale,
              centerX: 1262,
              label: 'Espace citoyen',
              iconPath: CitoyenPeyiHomePage.navProfilePath,
              fallbackIcon: Icons.person_rounded,
              routeName: '/espace-citoyen',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.scale,
    required this.centerX,
    required this.label,
    required this.iconPath,
    required this.fallbackIcon,
    required this.routeName,
    this.isActive = false,
  });

  final double scale;
  final double centerX;
  final String label;
  final String iconPath;
  final IconData fallbackIcon;
  final String routeName;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final itemColor = isActive ? const Color(0xFF005098) : const Color(0xFF4A4A4A);
    final itemWidth = 190 * scale;

    return Positioned(
      top: 34 * scale,
      left: (centerX * scale) - (itemWidth / 2),
      width: itemWidth,
      child: InkWell(
        borderRadius: BorderRadius.circular(24 * scale),
        onTap: () => Navigator.of(context).pushNamed(routeName),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: (isActive ? 86 : 58) * scale,
              height: 44 * scale,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF005098).withValues(alpha: 0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(24 * scale),
              ),
              child: _AssetOrIcon(
                path: iconPath,
                fallbackIcon: fallbackIcon,
                color: itemColor,
                size: 26 * scale,
              ),
            ),
            SizedBox(height: 13 * scale),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetOrIcon extends StatelessWidget {
  const _AssetOrIcon({
    required this.path,
    required this.fallbackIcon,
    required this.color,
    required this.size,
  });

  final String path;
  final IconData fallbackIcon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      errorBuilder: (_, __, ___) => Icon(
        fallbackIcon,
        color: color,
        size: size,
      ),
    );
  }
}