import 'package:flutter/material.dart';

import '../../theme/citizen_design_tokens.dart';

class CitizenPrimaryButton extends StatelessWidget {
  const CitizenPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.showArrow = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onPressed != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusButton),
          child: Ink(
            height: 58,
            decoration: CitizenDesignTokens.primaryButtonDecoration.copyWith(
              color: isEnabled
                  ? CitizenDesignTokens.yellow
                  : CitizenDesignTokens.cardBorder,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CitizenDesignTokens.deepBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (showArrow)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: CitizenDesignTokens.deepBlue,
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
