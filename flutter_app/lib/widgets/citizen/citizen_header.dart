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

    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: CitizenDesignTokens.headerGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (displayBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Retour',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
