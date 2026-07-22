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
    final displayBack = showBack ?? !_isRootTabTitle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final sideExtent = compact ? 42.0 : 52.0;
        final horizontalPadding = compact ? 8.0 : 14.0;

        return Container(
          width: double.infinity,
          height: compact ? height.clamp(92, 100).toDouble() : height,
          decoration: const BoxDecoration(
            gradient: CitizenDesignTokens.headerGradient,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
          ),
          child: SafeArea(
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
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 16.5 : 18,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
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
        );
      },
    );
  }
}
