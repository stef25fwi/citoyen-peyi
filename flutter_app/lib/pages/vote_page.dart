import 'package:flutter/material.dart';

import '../models/poll_models.dart';
import '../services/poll_service.dart';
import '../services/vote_access_service.dart';

class VotePage extends StatefulWidget {
  const VotePage({
    required this.token,
    super.key,
  });

  final String token;

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _selectedOptionId;
  PollModel? _poll;
  VoteAccessRecordModel? _accessRecord;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    var accessRecord = await VoteAccessService.instance.findByCode(widget.token);
    if (accessRecord != null && !accessRecord.activated && !accessRecord.hasVoted) {
      await VoteAccessService.instance.markActivated(widget.token);
      accessRecord = await VoteAccessService.instance.findByCode(widget.token);
    }

    final poll = accessRecord == null ? null : await PollService.instance.loadPollById(accessRecord.pollId);

    if (!mounted) {
      return;
    }

    setState(() {
      _accessRecord = accessRecord;
      _poll = poll;
      _isLoading = false;
    });
  }

  Future<void> _submitVote() async {
    if (_selectedOptionId == null || _accessRecord == null || _poll == null || _isSubmitting) {
      if (_selectedOptionId == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez selectionner une option.')),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await VoteAccessService.instance.markVoted(widget.token);
    await PollService.instance.recordVote(_accessRecord!.pollId, _selectedOptionId!);

    if (!mounted) {
      return;
    }

    setState(() {
      _submitted = true;
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vote enregistre avec succes.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _VoteStateScaffold(
        child: _InfoCard(
          title: 'Chargement de votre acces',
          message: 'Verification securisee du code en cours.',
        ),
      );
    }

    if (_accessRecord == null || _poll == null) {
      return _VoteStateScaffold(
        child: _InfoCard(
          title: 'Acces au sondage indisponible',
          message: 'Ce code n\'existe pas, a expire, ou le sondage associe est introuvable.',
          actionLabel: 'Retour',
          onPressed: () => Navigator.of(context).pushNamed('/access'),
        ),
      );
    }

    if (_accessRecord!.hasVoted || _submitted) {
      return _VoteStateScaffold(
        child: _InfoCard(
          title: 'Merci pour votre vote !',
          message: 'Votre vote a ete enregistre de maniere anonyme. Aucune trace ne relie votre identite a votre choix.',
          actionLabel: 'Retour a l\'accueil',
          onPressed: () => Navigator.of(context).pushNamed('/'),
          icon: Icons.verified_rounded,
        ),
      );
    }

    final poll = _poll!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF08354A), Color(0xFF0F6D8F)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pushNamed('/'),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    poll.projectTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    poll.question,
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Card(
                  color: const Color(0xFFF0F5F9),
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Vote anonyme : votre choix est enregistre sans lien avec votre identite.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...poll.options.map((option) {
                  final selected = _selectedOptionId == option.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        setState(() {
                          _selectedOptionId = option.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected ? const Color(0xFF0F6D8F) : const Color(0xFFD9E3EE),
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: selected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x220F6D8F),
                                    blurRadius: 22,
                                    offset: Offset(0, 10),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? const Color(0xFF0F6D8F) : Colors.transparent,
                                border: Border.all(
                                  color: selected ? const Color(0xFF0F6D8F) : const Color(0xFF9AA9B8),
                                  width: 2,
                                ),
                              ),
                              child: selected
                                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option.label,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: selected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitVote,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Enregistrement...' : 'Confirmer mon vote'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'En soumettant, votre vote sera definitif et anonymise.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoteStateScaffold extends StatelessWidget {
  const _VoteStateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
    this.icon = Icons.how_to_vote_rounded,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPressed,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}