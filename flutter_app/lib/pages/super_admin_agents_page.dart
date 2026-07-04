import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/controleur_profile_service.dart';

/// Vue super admin : tous les agents de mobilisation citoyenne créés,
/// regroupés par commune de rattachement.
class SuperAdminAgentsPage extends StatefulWidget {
  const SuperAdminAgentsPage({super.key});

  @override
  State<SuperAdminAgentsPage> createState() => _SuperAdminAgentsPageState();
}

class _SuperAdminAgentsPageState extends State<SuperAdminAgentsPage> {
  bool _isLoading = true;
  String? _error;
  List<ControleurProfileModel> _agents = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final agents = await ControleurProfileService.instance.loadProfiles();
      if (!mounted) return;
      setState(() {
        _agents = agents;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAgent(ControleurProfileModel agent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cet agent ?'),
        content: Text(
          'L\'agent "${agent.label}" de la commune "${agent.communeName}" '
          'sera supprimé définitivement. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ControleurProfileService.instance.deleteProfile(agent.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent supprimé.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _regenerateAgentCode(ControleurProfileModel agent) async {
    try {
      final regenerated = await ControleurProfileService.instance
          .regenerateProfileCode(agent.id);
      if (!mounted) return;
      _showCodeRevealDialog(regenerated, regenerated: true);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _showCodeRevealDialog(ControleurProfileModel profile, {bool regenerated = false}) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          regenerated ? 'Nouveau code généré' : 'Code de l\'agent',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${profile.label} (${profile.communeName})'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.code,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.code));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copié.')),
                      );
                    },
                    tooltip: 'Copier',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Map<String, List<ControleurProfileModel>> _groupByCommune() {
    final grouped = <String, List<ControleurProfileModel>>{};
    for (final agent in _agents) {
      final key = agent.communeName.trim().isNotEmpty
          ? agent.communeName.trim()
          : (agent.communeCode?.trim().isNotEmpty == true
              ? agent.communeCode!.trim()
              : 'Commune non renseignée');
      grouped.putIfAbsent(key, () => []).add(agent);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupByCommune();
    final communes = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Agents par commune'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Agents de mobilisation citoyenne',
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Tous les agents créés, regroupés par commune de rattachement '
                  '(${_agents.length} agent(s), ${communes.length} commune(s)).',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Card(
                    color: const Color(0xFFFFEBEB),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!,
                          style: const TextStyle(color: Color(0xFFB42318))),
                    ),
                  )
                else if (communes.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Aucun agent créé pour le moment.')),
                    ),
                  )
                else
                  for (final commune in communes)
                    _CommuneAgentsCard(
                      commune: commune,
                      agents: grouped[commune]!,
                      onRegenerate: _regenerateAgentCode,
                      onDelete: _deleteAgent,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommuneAgentsCard extends StatelessWidget {
  const _CommuneAgentsCard({
    required this.commune,
    required this.agents,
    required this.onRegenerate,
    required this.onDelete,
  });

  final String commune;
  final List<ControleurProfileModel> agents;
  final void Function(ControleurProfileModel agent) onRegenerate;
  final void Function(ControleurProfileModel agent) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_city_rounded,
                      color: Color(0xFF0F6D8F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(commune,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Chip(label: Text('${agents.length}')),
                ],
              ),
              const Divider(height: 20),
              for (final agent in agents)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined,
                          size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(agent.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              'Code ${agent.displayCodeMasked.isEmpty ? '—' : agent.displayCodeMasked} · '
                              'créé le ${_formatFrenchDateTime(agent.createdAt)}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      _UsageBadge(used: agent.hasBeenUsed),
                      const SizedBox(width: 8),
                      _AgentActionButtons(
                        agent: agent,
                        onRegenerate: () => onRegenerate(agent),
                        onDelete: () => onDelete(agent),
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

class _UsageBadge extends StatelessWidget {
  const _UsageBadge({required this.used});

  final bool used;

  @override
  Widget build(BuildContext context) {
    final color = used ? const Color(0xFF15803D) : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(used ? 'Activé' : 'Jamais utilisé',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _AgentActionButtons extends StatelessWidget {
  const _AgentActionButtons({
    required this.agent,
    required this.onRegenerate,
    required this.onDelete,
  });

  final ControleurProfileModel agent;
  final VoidCallback onRegenerate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: onRegenerate,
          tooltip: 'Régénérer le code',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              size: 20, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Supprimer',
        ),
      ],
    );
  }
}

/// Format jj/mm/aa hh:mm (heure locale).
String _formatFrenchDateTime(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${two(d.year % 100)} '
      '${two(d.hour)}:${two(d.minute)}';
}
