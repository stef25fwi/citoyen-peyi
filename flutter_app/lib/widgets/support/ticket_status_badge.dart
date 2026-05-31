import 'package:flutter/material.dart';

class TicketStatusBadge extends StatelessWidget {
  const TicketStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ouvert' => const Color(0xFF0D73F2),
      'en_cours' => const Color(0xFFF59E0B),
      'en_attente_admin' => const Color(0xFF8B5CF6),
      'resolu' => const Color(0xFF16A34A),
      'ferme' => const Color(0xFF64748B),
      _ => const Color(0xFF64748B),
    };
    final label = switch (status) {
      'ouvert' => 'Ouvert',
      'en_cours' => 'En cours',
      'en_attente_admin' => 'En attente admin',
      'resolu' => 'Résolu',
      'ferme' => 'Fermé',
      _ => status,
    };
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.20)),
    );
  }
}
