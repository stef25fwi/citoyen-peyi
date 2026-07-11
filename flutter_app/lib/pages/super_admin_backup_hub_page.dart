import 'package:flutter/material.dart';

class SuperAdminBackupHubPage extends StatelessWidget {
  const SuperAdminBackupHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: const Text('Sauvegardes & historique')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Sauvegardes & historique', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Retrouvez les sauvegardes JSON complètes et le récapitulatif des éléments supprimés par le super administrateur.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              _HubCard(
                icon: Icons.cloud_upload_rounded,
                title: 'Sauvegardes et restauration',
                subtitle: 'Créer une sauvegarde, télécharger un snapshot ou lancer une restauration contrôlée.',
                actionLabel: 'Ouvrir les sauvegardes',
                onTap: () => Navigator.of(context).pushNamed('/super/backups/list'),
              ),
              const SizedBox(height: 12),
              _HubCard(
                icon: Icons.history_rounded,
                title: 'Historique des suppressions',
                subtitle: 'Voir les comptes admin communaux et agents supprimés, avec les données archivées.',
                actionLabel: 'Voir l’historique',
                onTap: () => Navigator.of(context).pushNamed('/super/deleted-records'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(actionLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
