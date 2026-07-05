import 'package:flutter/material.dart';

import '../../theme/citizen_design_tokens.dart';

class CitizenCard extends StatelessWidget {
  const CitizenCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = CitizenDesignTokens.cardDecoration.copyWith(
      color: color ?? CitizenDesignTokens.white,
    );

    final card = Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusCard),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
