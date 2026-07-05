import 'package:flutter/material.dart';

import '../../theme/citizen_design_tokens.dart';
import 'citizen_card.dart';
import 'citizen_primary_button.dart';

class ConsultationCard extends StatelessWidget {
  const ConsultationCard({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.participationLabel,
    required this.illustrationIcon,
    required this.onPressed,
    this.badge,
  });

  final String title;
  final String dateLabel;
  final String participationLabel;
  final IconData illustrationIcon;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return CitizenCard(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ConsultationTextContent(
                  badge: badge,
                  title: title,
                  dateLabel: dateLabel,
                  participationLabel: participationLabel,
                ),
              ),
              const SizedBox(width: 12),
              _IllustrationBox(icon: illustrationIcon),
            ],
          ),
          const SizedBox(height: 12),
          CitizenPrimaryButton(
            label: 'Je donne mon avis',
            showArrow: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _ConsultationTextContent extends StatelessWidget {
  const _ConsultationTextContent({
    required this.badge,
    required this.title,
    required this.dateLabel,
    required this.participationLabel,
  });

  final String? badge;
  final String title;
  final String dateLabel;
  final String participationLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF28C7F3),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CitizenDesignTokens.textDark,
            fontSize: 17,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _MetaRow(icon: Icons.calendar_month_rounded, text: dateLabel),
        const SizedBox(height: 5),
        _MetaRow(icon: Icons.groups_rounded, text: participationLabel),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: CitizenDesignTokens.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: CitizenDesignTokens.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _IllustrationBox extends StatelessWidget {
  const _IllustrationBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: CitizenDesignTokens.skyBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        size: 48,
        color: CitizenDesignTokens.primaryBlue,
      ),
    );
  }
}
