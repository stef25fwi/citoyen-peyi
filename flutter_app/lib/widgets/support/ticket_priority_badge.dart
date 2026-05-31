import 'package:flutter/material.dart';

class TicketPriorityBadge extends StatelessWidget {
  const TicketPriorityBadge({required this.priority, super.key});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'faible' => const Color(0xFF64748B),
      'normale' => const Color(0xFF0D73F2),
      'urgente' => const Color(0xFFDC2626),
      _ => const Color(0xFF64748B),
    };
    final label = switch (priority) {
      'faible' => 'Faible',
      'normale' => 'Normale',
      'urgente' => 'Urgente',
      _ => priority,
    };
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.20)),
    );
  }
}
