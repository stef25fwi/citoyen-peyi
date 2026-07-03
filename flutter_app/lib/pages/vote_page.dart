import 'package:flutter/material.dart';

import '../services/vote_access_service.dart';

/// Page de vote citoyen.
///
/// Tout le parcours s'appuie sur le backend transactionnel:
///   POST /api/vote-access/validate -> recupere un accessToken minimal par consultation eligible
///   POST /api/vote-access/submit   -> enregistre le vote en transaction Firestore
///
/// Le client n'incremente plus de compteur localement et ne marque plus le code
/// comme "vote" en deux appels separes: le backend garantit l'atomicite et
/// empeche le double vote via une participation consommee separee du bulletin.
class VotePage extends StatefulWidget {
  const VotePage({
    required this.token,
    this.pollId,
    this.voteAccessService,
    super.key,
  });

  /// Code citoyen brut, URL QR ou token transmis dans l'URL `/vote/:token`.
  final String token;
  final String? pollId;
  final VoteAccessService? voteAccessService;

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedOptionId;
  VoteAccessValidationResult? _validation;
  EligiblePollModel? _activePoll;
  String? _errorMessage;
  String? _successReceipt;

  VoteAccessService get _voteAccessService =>
      widget.voteAccessService ?? VoteAccessService.instance;

  @override
  void initState() {
    super.initState();
    _validate();
  }

  Future<void> _validate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _voteAccessService.validateCode(
        widget.token,
        pollId: widget.pollId,
      );
      EligiblePollModel? poll;
      if (widget.pollId != null && widget.pollId!.isNotEmpty) {
        for (final candidate in result.eligiblePolls) {
          if (candidate.pollId == widget.pollId) {
            poll = candidate;
            break;
          }
        }
      } else if (result.eligiblePolls.length == 1) {
        poll = result.eligiblePolls.first;
      }

      if (!mounted) return;
      setState(() {
        _validation = result;
        _activePoll = poll;
        _isLoading = false;
      });
    } on VoteAccessException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Validation du code impossible. Reessayez plus tard.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitVote() async {
    final validation = _validation;
    final poll = _activePoll;
    final optionId = _selectedOptionId;
    if (_isSubmitting ||
        validation == null ||
        poll == null ||
        optionId == null) {
      if (optionId == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez selectionner une option.')),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _voteAccessService.submitVote(
        accessToken: poll.accessToken.isNotEmpty
            ? poll.accessToken
            : validation.accessToken,
        pollId: poll.pollId,
        optionId: optionId,
      );
      if (!mounted) return;
      setState(() {
        _successReceipt = result.receiptId;
        _isSubmitting = false;
      });
      Navigator.of(context).pushReplacementNamed(
        '/confirmation',
        arguments: {
          'pollTitle': poll.title,
          'communeName': validation.communeName,
        },
      );
    } on VoteAccessException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Reseau indisponible. Votre vote n\'a pas ete enregistre.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _VoteStateScaffold(
        child: _InfoCard(
          title: 'Verification securisee',
          message:
              'Validation de votre code citoyen par le serveur en cours...',
        ),
      );
    }

    if (_errorMessage != null && _validation == null) {
      return _VoteStateScaffold(
        child: _InfoCard(
          title: 'Acces a la consultation indisponible',
          message: _errorMessage!,
          actionLabel: 'Retour',
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/access'),
        ),
      );
    }

    final validation = _validation!;
    final polls = validation.eligiblePolls;

    if (_activePoll == null) {
      if (polls.isEmpty) {
        return _VoteStateScaffold(
          child: _InfoCard(
            title: 'Aucune consultation ouverte',
            message:
                'Aucune consultation n\'est ouverte pour votre commune actuellement.',
            actionLabel: 'Retour a l\'accueil',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        );
      }

      return _VoteStateScaffold(
        child: _PollPicker(
          polls: polls,
          communeName: validation.communeName,
          onSelected: (poll) {
            if (poll.hasVoted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Vous avez deja vote pour cette consultation.')),
              );
              return;
            }
            setState(() {
              _activePoll = poll;
              _selectedOptionId = null;
              _errorMessage = null;
            });
          },
        ),
      );
    }

    final poll = _activePoll!;
    if (poll.hasVoted) {
      return _VoteStateScaffold(
        child: _InfoCard(
          title: 'Merci pour votre vote',
          message:
              'Votre vote a deja ete enregistre de maniere anonyme. Aucune trace ne relie votre identite a votre choix.',
          actionLabel: 'Retour a l\'accueil',
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          icon: Icons.verified_rounded,
        ),
      );
    }

    return _buildVotingScaffold(poll);
  }

  Widget _buildVotingScaffold(EligiblePollModel poll) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFBFE8FF),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(6, 48, 6, 24),
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
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pushReplacementNamed('/'),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    poll.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    poll.question.isNotEmpty
                        ? poll.question
                        : 'Choisissez votre option',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  if (poll.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      poll.description,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(6, 20, 6, 28),
              children: [
                if (poll.photoUrls.isNotEmpty) ...[
                  _VotePollPhotoGallery(photoUrls: poll.photoUrls),
                  const SizedBox(height: 16),
                ],
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
                _PollOptions(
                  poll: poll,
                  selectedOptionId: _selectedOptionId,
                  enabled: !_isSubmitting,
                  onChanged: (value) =>
                      setState(() => _selectedOptionId = value),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Card(
                      color: const Color(0xFFFFEBEB),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFB42318)),
                        ),
                      ),
                    ),
                  ),
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
                  onPressed: _isSubmitting || _selectedOptionId == null
                      ? null
                      : _submitVote,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting
                      ? 'Enregistrement...'
                      : 'Confirmer mon vote'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'En soumettant, votre vote sera definitif et anonymise.',
                textAlign: TextAlign.center,
              ),
              if (_successReceipt != null) ...[
                const SizedBox(height: 6),
                Text('Recu: $_successReceipt',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VotePollPhotoGallery extends StatefulWidget {
  const _VotePollPhotoGallery({required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<_VotePollPhotoGallery> createState() => _VotePollPhotoGalleryState();
}

class _VotePollPhotoGalleryState extends State<_VotePollPhotoGallery> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedUrl = widget.photoUrls[_selectedIndex];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  selectedUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const ColoredBox(
                      color: Color(0xFFE2E8F0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(
                    color: Color(0xFFE2E8F0),
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
            if (widget.photoUrls.length > 1) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0;
                        index < widget.photoUrls.length;
                        index++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: index == widget.photoUrls.length - 1 ? 0 : 10,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selectedIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 78,
                            height: 58,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedIndex == index
                                    ? const Color(0xFF0F6D8F)
                                    : const Color(0xFFD7E0EA),
                                width: _selectedIndex == index ? 3 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.photoUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const ColoredBox(
                                  color: Color(0xFFE2E8F0),
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PollOptions extends StatelessWidget {
  const _PollOptions({
    required this.poll,
    required this.selectedOptionId,
    required this.enabled,
    required this.onChanged,
  });

  final EligiblePollModel poll;
  final String? selectedOptionId;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = poll.options;
    if (options.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Cette consultation ne propose pas encore d\'options. Reessayez plus tard.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: enabled ? () => onChanged(option.id) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selectedOptionId == option.id
                        ? const Color(0xFF0F6D8F)
                        : const Color(0xFFD9E3EE),
                    width: selectedOptionId == option.id ? 2 : 1,
                  ),
                  boxShadow: selectedOptionId == option.id
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
                        color: selectedOptionId == option.id
                            ? const Color(0xFF0F6D8F)
                            : Colors.transparent,
                        border: Border.all(
                          color: selectedOptionId == option.id
                              ? const Color(0xFF0F6D8F)
                              : const Color(0xFF9AA9B8),
                          width: 2,
                        ),
                      ),
                      child: selectedOptionId == option.id
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selectedOptionId == option.id
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PollPicker extends StatelessWidget {
  const _PollPicker({
    required this.polls,
    required this.communeName,
    required this.onSelected,
  });

  final List<EligiblePollModel> polls;
  final String communeName;
  final ValueChanged<EligiblePollModel> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choisissez une consultation',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Commune: $communeName', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            for (final poll in polls)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFD7E0EA)),
                  ),
                  title: Text(poll.title),
                  subtitle: Text(poll.question.isEmpty
                      ? 'Consultation ouverte'
                      : poll.question),
                  trailing: poll.hasVoted
                      ? const Chip(label: Text('Deja vote'))
                      : const Icon(Icons.arrow_forward_rounded),
                  onTap: () => onSelected(poll),
                ),
              ),
          ],
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
      backgroundColor: const Color(0xFFBFE8FF),
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
            Text(title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message,
                style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
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
