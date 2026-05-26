import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/citizen_access_code_service.dart';
import '../services/poll_service.dart';

class PollDetailPage extends StatefulWidget {
  const PollDetailPage({
    required this.pollId,
    super.key,
  });

  final String pollId;

  @override
  State<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends State<PollDetailPage> {
  bool _isLoading = true;
  bool _isStatusSubmitting = false;
  PollModel? _poll;
  List<CitizenAccessCodeModel> _citizenCodes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    final poll = await PollService.instance.loadPollById(widget.pollId);
    final citizenCodes = poll == null
      ? const <CitizenAccessCodeModel>[]
      : await CitizenAccessCodeService.instance.loadAccessCodesForCurrentCommune();

    if (!mounted) {
      return;
    }

    setState(() {
      _poll = poll;
      _citizenCodes = citizenCodes;
      _isLoading = false;
    });
  }

  Future<void> _changeStatus({
    required String actionLabel,
    required Future<PollModel?> Function(String pollId) action,
  }) async {
    final poll = _poll;
    if (poll == null || _isStatusSubmitting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$actionLabel la consultation ?'),
        content: Text('Cette action sera appliquee a "${poll.projectTitle}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(actionLabel)),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _isStatusSubmitting = true);
    try {
      final updated = await action(poll.id);
      if (!mounted) return;
      if (updated == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation introuvable.')),
        );
        return;
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consultation ${actionLabel.toLowerCase()}e.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isStatusSubmitting = false);
      }
    }
  }

  Future<void> _deletePoll() async {
    final poll = _poll;
    if (poll == null || _isStatusSubmitting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la consultation ?'),
        content: Text('La consultation "${poll.projectTitle}" sera supprimee definitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _isStatusSubmitting = true);
    try {
      await PollService.instance.deletePoll(poll.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation supprimee.')),
      );
      Navigator.of(context).pushReplacementNamed('/admin/polls');
    } finally {
      if (mounted) {
        setState(() => _isStatusSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = _poll;

    return Scaffold(
      appBar: AppBar(
        title: Text(poll?.projectTitle ?? 'Detail du sondage'),
        actions: poll == null
            ? null
            : [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/admin/polls/${poll.id}/edit'),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Modifier'),
                ),
              ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : poll == null
                  ? _EmptyPollState(onBack: () => Navigator.of(context).pushNamed('/admin'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _PollHeroCard(poll: poll),
                          const SizedBox(height: 20),
                          _PollActionsCard(
                            poll: poll,
                            isSubmitting: _isStatusSubmitting,
                            onPublish: poll.status == 'draft'
                                ? () => _changeStatus(
                                      actionLabel: 'Publier',
                                      action: PollService.instance.publishPoll,
                                    )
                                : null,
                            onClose: poll.status == 'active'
                                ? () => _changeStatus(
                                      actionLabel: 'Cloturer',
                                      action: PollService.instance.closePoll,
                                    )
                                : null,
                            onArchive: poll.status != 'archived'
                                ? () => _changeStatus(
                                      actionLabel: 'Archiver',
                                      action: PollService.instance.archivePoll,
                                    )
                                : null,
                            onDelete: poll.totalVoted == 0 ? _deletePoll : null,
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 860;
                              final results = _ResultsCard(poll: poll);
                              final side = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _InfoCard(poll: poll),
                                  const SizedBox(height: 16),
                                  _CitizenAccessCard(codes: _citizenCodes, poll: poll),
                                  const SizedBox(height: 16),
                                  _VoteAnonymityCard(poll: poll),
                                ],
                              );

                              if (wide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 2, child: results),
                                    const SizedBox(width: 16),
                                    Expanded(child: side),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  results,
                                  const SizedBox(height: 16),
                                  side,
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _PollHeroCard extends StatelessWidget {
  const _PollHeroCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participation = poll.totalVoters == 0 ? 0.0 : poll.totalVoted / poll.totalVoters;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08354A), Color(0xFF0F6D8F)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.projectTitle,
              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              poll.question,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.84)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HeroStat(label: 'Statut', value: _statusLabel(poll.status)),
                _HeroStat(label: 'Participation', value: '${poll.totalVoted}/${poll.totalVoters}'),
                _HeroStat(label: 'Taux', value: '${(participation * 100).round()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'En cours';
      case 'closed':
        return 'Termine';
      case 'archived':
        return 'Archive';
      default:
        return 'Brouillon';
    }
  }
}

class _PollActionsCard extends StatelessWidget {
  const _PollActionsCard({
    required this.poll,
    required this.isSubmitting,
    required this.onPublish,
    required this.onClose,
    required this.onArchive,
    required this.onDelete,
  });

  final PollModel poll;
  final bool isSubmitting;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions de gestion', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(
              'Publiez, cloturez ou archivez la consultation selon son etat courant. La suppression n\'est autorisee que sans vote enregistre.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: isSubmitting ? null : onPublish,
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text('Publier'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isSubmitting ? null : onClose,
                  icon: const Icon(Icons.lock_clock_rounded),
                  label: const Text('Cloturer'),
                ),
                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onArchive,
                  icon: const Icon(Icons.archive_rounded),
                  label: const Text('Archiver'),
                ),
                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Supprimer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.options.fold<int>(0, (sum, option) => sum + option.votes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultats agreges', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('$totalVotes vote(s) enregistres'),
            const SizedBox(height: 18),
            for (final option in poll.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ResultRow(option: option, totalVotes: totalVotes),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.option, required this.totalVotes});

  final PollOptionModel option;
  final int totalVotes;

  @override
  Widget build(BuildContext context) {
    final ratio = totalVotes == 0 ? 0.0 : option.votes / totalVotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(option.label, style: Theme.of(context).textTheme.titleSmall)),
            Text('${option.votes}'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: ratio),
        const SizedBox(height: 6),
        Text('${(ratio * 100).round()}% des suffrages'),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _InfoRow(label: 'Statut', value: poll.status),
            _InfoRow(label: 'Ouverture', value: poll.openDate),
            _InfoRow(label: 'Fermeture', value: poll.closeDate),
            _InfoRow(label: 'Participation', value: '${poll.totalVoted}/${poll.totalVoters}'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CitizenAccessCard extends StatelessWidget {
  const _CitizenAccessCard({required this.codes, required this.poll});

  final List<CitizenAccessCodeModel> codes;
  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    final activeCodes = codes.where((item) => item.status == 'active').length;
    final usedCodes = codes.where((item) => item.usedForLogin).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Acces citoyens', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Les agents de mobilisation citoyenne generent les codes citoyens a l\'accueil apres verification physique. Cette consultation n\'utilise pas de stock QR dedie.'),
            const SizedBox(height: 16),
            _InfoRow(label: 'Commune', value: poll.communeName.isEmpty ? 'Non renseignee' : poll.communeName),
            _InfoRow(label: 'Codes citoyens actifs', value: '$activeCodes'),
            _InfoRow(label: 'Codes deja utilises', value: '$usedCodes'),
            _InfoRow(label: 'Votes anonymes enregistres', value: '${poll.totalVoted}'),
          ],
        ),
      ),
    );
  }
}

class _VoteAnonymityCard extends StatelessWidget {
  const _VoteAnonymityCard({required this.poll});

  final PollModel poll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Garantie d\'anonymat', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('Le code citoyen ouvre l\'espace de vote sans relier l\'identite reelle au choix exprime.'),
            const SizedBox(height: 14),
            _InfoRow(label: 'Consultation', value: poll.projectTitle),
            _InfoRow(label: 'Question', value: poll.question),
            _InfoRow(label: 'Rappel', value: 'Votre identite n\'est pas liee a votre choix.'),
          ],
        ),
      ),
    );
  }
}

class _EmptyPollState extends StatelessWidget {
  const _EmptyPollState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.poll_outlined, size: 42),
                const SizedBox(height: 16),
                Text('Consultation introuvable', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                const Text('La consultation demandee n\'existe pas ou n\'est plus disponible.'),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onBack,
                  child: const Text('Retour au tableau de bord'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}