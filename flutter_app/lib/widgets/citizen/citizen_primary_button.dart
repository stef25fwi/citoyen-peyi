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
    final theme = Theme.of(context);
    final isEnabled = enabled && onPressed != null;
    final borderRadius =
        BorderRadius.circular(CitizenDesignTokens.radiusButton);

    return Opacity(
      opacity: isEnabled ? 1 : 0.62,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: borderRadius,
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              gradient:
                  isEnabled ? CitizenDesignTokens.actionGradient : null,
              color: isEnabled ? null : CitizenDesignTokens.backgroundStrong,
              borderRadius: borderRadius,
              border: Border.all(
                color: isEnabled
                    ? CitizenDesignTokens.yellowStrong
                    : CitizenDesignTokens.cardBorder,
              ),
              boxShadow:
                  isEnabled ? CitizenDesignTokens.softShadow : const [],
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isEnabled
                            ? CitizenDesignTokens.navy
                            : CitizenDesignTokens.textMuted,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (showArrow)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
                      color: isEnabled
                          ? CitizenDesignTokens.navy
                          : CitizenDesignTokens.textMuted,
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