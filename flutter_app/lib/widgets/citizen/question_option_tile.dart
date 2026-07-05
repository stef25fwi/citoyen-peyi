import 'package:flutter/material.dart';

import '../../theme/citizen_design_tokens.dart';

class QuestionOptionTile extends StatelessWidget {
  const QuestionOptionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusSmall),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CitizenDesignTokens.lightBlue,
            borderRadius:
                BorderRadius.circular(CitizenDesignTokens.radiusSmall),
            border: Border.all(
              color: selected
                  ? CitizenDesignTokens.primaryBlue
                  : CitizenDesignTokens.cardBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: CitizenDesignTokens.skyBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: CitizenDesignTokens.primaryBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: CitizenDesignTokens.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? CitizenDesignTokens.primaryBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: selected
                        ? CitizenDesignTokens.primaryBlue
                        : CitizenDesignTokens.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
