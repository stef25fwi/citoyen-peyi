import 'package:flutter/material.dart';

import '../../theme/citizen_design_tokens.dart';

class CitizenHeader extends StatelessWidget {
  const CitizenHeader({
    super.key,
    required this.title,
    this.showBack,
    this.trailing,
    this.height = 104,
  });

  final String title;
  final bool? showBack;
  final Widget? trailing;
  final double height;

  bool get _isRootTabTitle {
    return title == 'Actualités / Projets' ||
        title == 'Résultats des consultations' ||
        title == 'Donner mon avis';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayBack = showBack ?? !_isRootTabTitle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final sideExtent = compact ? 42.0 : 52.0;
        final horizontalPadding = compact ? 8.0 : 14.0;

        return Container(
          width: double.infinity,
          height: compact ? height.clamp(92, 100).toDouble() : height,
          decoration: BoxDecoration(
            gradient: CitizenDesignTokens.headerGradient,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26004D7A),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -34,
                top: -54,
                child: IgnorePointer(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CitizenDesignTokens.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -52,
                bottom: -82,
                child: IgnorePointer(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            CitizenDesignTokens.white.withValues(alpha: 0.08),
                        width: 22,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (displayBack)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: sideExtent,
                            child: IconButton(
                              tooltip: 'Retour',
                              onPressed: () => Navigator.maybePop(context),
                              style: IconButton.styleFrom(
                                foregroundColor: CitizenDesignTokens.white,
                                backgroundColor: CitizenDesignTokens.white
                                    .withValues(alpha: 0.10),
                              ),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: sideExtent),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: compact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: CitizenDesignTokens.white,
                            fontSize: compact ? 16.5 : 18,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (trailing != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: sideExtent,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: trailing!,
                            ),
                          ),
                        ),
                    ],
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
