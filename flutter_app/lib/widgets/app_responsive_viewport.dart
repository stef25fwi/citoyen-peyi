import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/citizen_design_tokens.dart';

/// Cadre responsive global appliqué au-dessus du Navigator.
///
/// Toutes les routes, y compris celles ouvertes avec un MaterialPageRoute
/// directement depuis une page, passent par les mêmes règles visuelles :
/// - plein écran sous 600 px ;
/// - marges progressives sur tablette et desktop ;
/// - largeur maximale de 1 200 px ;
/// - surface et ombre cohérentes avec le design system premium ;
/// - MediaQuery recalculée à la largeur réellement disponible.
class AppResponsiveViewport extends StatelessWidget {
  const AppResponsiveViewport({
    required this.child,
    super.key,
    this.maxWidth = 1200,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.size.width;
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.size.height;
        final isMobile = viewportWidth < 600;
        final horizontalGutter = isMobile
            ? 0.0
            : viewportWidth < 1024
                ? 16.0
                : 24.0;
        final availableWidth = math
            .max(
              0.0,
              viewportWidth - (horizontalGutter * 2),
            )
            .toDouble();
        final frameWidth = math.min(availableWidth, maxWidth).toDouble();
        final radius = isMobile ? 0.0 : CitizenDesignTokens.radiusLarge;
        final adjustedMedia = media.copyWith(
          size: Size(frameWidth, media.size.height),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: CitizenDesignTokens.background,
            gradient:
                isMobile ? null : CitizenDesignTokens.softBackgroundGradient,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalGutter),
              child: SizedBox(
                width: frameWidth,
                height: viewportHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CitizenDesignTokens.surface,
                    borderRadius: BorderRadius.circular(radius),
                    border: isMobile
                        ? null
                        : Border.all(
                            color: CitizenDesignTokens.white,
                            width: 1.2,
                          ),
                    boxShadow:
                        isMobile ? null : CitizenDesignTokens.raisedShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: MediaQuery(
                      data: adjustedMedia,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Largeur et marges de contenu communes aux écrans qui souhaitent aller plus
/// loin que le cadre global, sans réintroduire de valeurs fixes page par page.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    super.key,
    this.maxContentWidth = 1100,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxContentWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sidePadding = width < 340
            ? 12.0
            : width < 600
                ? 16.0
                : width < 900
                    ? 24.0
                    : 32.0;
        final contentWidth = math
            .min(
              math.max(0.0, width - (sidePadding * 2)),
              maxContentWidth,
            )
            .toDouble();

        return Align(
          alignment: alignment,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: SizedBox(width: contentWidth, child: child),
          ),
        );
      },
    );
  }
}

extension ResponsiveContext on BuildContext {
  double get responsiveWidth => MediaQuery.sizeOf(this).width;

  bool get isCompactScreen => responsiveWidth < 360;

  bool get isMobileScreen => responsiveWidth < 600;

  bool get isTabletScreen => responsiveWidth >= 600 && responsiveWidth < 1024;

  bool get isDesktopScreen => responsiveWidth >= 1024;
}