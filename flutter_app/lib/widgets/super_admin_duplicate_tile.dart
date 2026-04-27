import 'package:flutter/material.dart';

import '../services/citizen_access_code_service.dart';

class SuperAdminDuplicateTile extends StatelessWidget {
  const SuperAdminDuplicateTile({
    required this.pendingCount,
    required this.latestRequests,
    required this.onOpen,
    super.key,
  });

  final int pendingCount;
  final List<DuplicateCodeRequestModel> latestRequests;
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
                  const Icon(Icons.content_copy_rounded, color: Color(0xFF0F6D8F)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Doublons a verifier', style: theme.textTheme.titleLarge)),
                  Badge(label: Text('$pendingCount')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                pendingCount == 0
                    ? 'Aucune demande en attente.'
                    : '$pendingCount demande(s) en attente de decision superadmin.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final request in latestRequests.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${request.communeName} · ${request.requestedByControllerName} · ${request.sourceKeyMasked} · ${request.status}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Ouvrir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}