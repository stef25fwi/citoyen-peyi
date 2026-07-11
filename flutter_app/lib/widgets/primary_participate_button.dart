import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/access_citizen_page.dart';
import '../theme/citoyen_theme.dart';

/// Bouton principal « Je participe » utilisé sur l'accueil et les pages
/// publiques pour conserver exactement la même couleur, le même dégradé et
/// le même ombrage.
class PrimaryParticipateButton extends StatelessWidget {
  const PrimaryParticipateButton({
    super.key,
    this.widthFactor,
  });

  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final buttonHeight = compact ? 72.0 : 92.0;
    final textSize = compact ? 28.0 : 40.0;
    final circleSize = compact ? 44.0 : 54.0;
    final iconSize = compact ? 28.0 : 34.0;

    return FractionallySizedBox(
      widthFactor: widthFactor ?? (compact ? 1 : 0.82),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE875),
              cpYellow,
              cpYellowStrong,
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: cpYellowStrong.withValues(alpha: 0.42),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(48),
            onTap: () =>
                Navigator.of(context).pushNamed(AccessCitizenPage.routeName),
            child: SizedBox(
              height: buttonHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Je participe',
                      style: GoogleFonts.inter(
                        color: cpBlueDark,
                        fontSize: textSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  Positioned(
                    right: compact ? 18 : 30,
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.92),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: cpBlueDark,
                        size: iconSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
