import 'package:flutter/material.dart';

import '../services/citizen_access_code_service.dart';

class SuperAdminControllerActivityTile extends StatelessWidget {
  const SuperAdminControllerActivityTile({
    required this.analytics,
    required this.onOpen,
    super.key,
  });

  final ControllerActivityAnalytics analytics;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timeline_rounded, color: Color(0xFF0F6D8F)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Activite des controleurs', style: theme.textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Metric(label: 'Codes', value: analytics.totalCodesGenerated),
                  _Metric(label: 'Doublons', value: analytics.duplicatesDetected),
                  _Metric(label: 'Demandes', value: analytics.regenerationRequests),
                  _Metric(label: 'Validees', value: analytics.regenerationsApproved),
                  _Metric(label: 'Refusees', value: analytics.regenerationsRejected),
                  _Metric(label: 'Connexions', value: analytics.loginCodesUsed),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                analytics.lastActivity == null
                    ? 'Aucune activite enregistree.'
                    : 'Derniere activite : ${analytics.lastActivity!.controllerName} · ${analytics.lastActivity!.actionType}',
                style: theme.textTheme.bodyMedium,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Voir activite'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}