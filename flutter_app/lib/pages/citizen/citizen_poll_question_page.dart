import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/citizen_public_access_service.dart';
import '../../services/vote_access_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_bottom_nav.dart';
import '../../widgets/citizen/citizen_header.dart';
import '../../widgets/poll_option_icons.dart';

class CitizenPollQuestionPage extends StatefulWidget {
  const CitizenPollQuestionPage({
    super.key,
    this.title = 'Consultation',
    this.pollId,
    this.accessCode,
    this.voteAccessService,
  });

  final String title;
  final String? pollId;
  final String? accessCode;
  final VoteAccessService? voteAccessService;

  @override
  State<CitizenPollQuestionPage> createState() =>
      _CitizenPollQuestionPageState();
}

class _CitizenPollQuestionPageState extends State<CitizenPollQuestionPage> {
  VoteAccessService get _service =>
      widget.voteAccessService ?? VoteAccessService.instance;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  VoteAccessValidationResult? _validation;
  EligiblePollModel? _poll;
  int _stepIndex = 0;
  final Map<String, Set<String>> _answers = {};

  CitizenPublicAccessSession? get _session =>
      CitizenPublicAccessService.instance.currentSession;

  @override
  void initState() {
    super.initState();
    _loadPoll();
  }

  Future<void> _loadPoll() async {
    final pollId = widget.pollId?.trim();
    final accessCode = widget.accessCode?.trim() ?? _session?.accessCode.trim();
    if (pollId == null ||
        pollId.isEmpty ||
        accessCode == null ||
        accessCode.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/access');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.validateCode(accessCode, pollId: pollId);
      EligiblePollModel? selectedPoll;
      for (final candidate in result.eligiblePolls) {
        if (candidate.pollId == pollId) {
          selectedPoll = candidate;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _validation = result;
        _poll = selectedPoll;
        _isLoading = false;
        _errorMessage = selectedPoll == null
            ? 'Cette consultation n’est plus disponible.'
            : null;
      });
    } on VoteAccessException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Validation du code impossible. Réessayez plus tard.';
      });
    }
  }

  List<EligiblePollQuestion> get _questions =>
      _poll?.effectiveQuestions ?? const <EligiblePollQuestion>[];

  EligiblePollQuestion? get _currentQuestion {
    if (_stepIndex < 0 || _stepIndex >= _questions.length) return null;
    return _questions[_stepIndex];
  }

  bool get _canContinue {
    final question = _currentQuestion;
    return question != null && _answers[question.id]?.isNotEmpty == true;
  }

  void _toggleOption(EligiblePollQuestion question, String optionId) {
    setState(() {
      final selected = _answers.putIfAbsent(question.id, () => <String>{});
      if (question.multiple) {
        selected.contains(optionId)
            ? selected.remove(optionId)
            : selected.add(optionId);
      } else {
        selected
          ..clear()
          ..add(optionId);
      }
    });
  }

  void _goNext() {
    if (!_canContinue || _isSubmitting) return;
    if (_stepIndex < _questions.length - 1) {
      setState(() => _stepIndex += 1);
      return;
    }
    _submitAnswers();
  }

  Future<void> _submitAnswers() async {
    final poll = _poll;
    final validation = _validation;
    final accessCode = widget.accessCode?.trim() ?? _session?.accessCode.trim();
    if (poll == null || validation == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final answers = _questions
        .map(
          (question) => PollAnswer(
            questionId: question.id,
            optionIds: _answers[question.id]?.toList() ?? const <String>[],
          ),
        )
        .toList(growable: false);

    try {
      await _service.submitVote(
        accessToken:
            poll.accessToken.isNotEmpty ? poll.accessToken : validation.accessToken,
        pollId: poll.pollId,
        answers: answers,
      );
      if (accessCode != null && accessCode.isNotEmpty) {
        await CitizenPublicAccessService.instance.markVoted(
          accessCode: accessCode,
          pollId: poll.pollId,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/citizen/vote-confirmation'),
          builder: (_) => _VoteConfirmationPage(title: widget.title),
        ),
      );
    } on VoteAccessException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Réseau indisponible. Votre vote n’a pas été enregistré.';
      });
    }
  }

  void _shareConsultation() {
    final pollId = widget.pollId?.trim();
    final base = Uri.base;
    final origin = base.scheme == 'http' || base.scheme == 'https'
        ? '${base.origin}${base.path}'
        : '';
    final link = pollId != null && pollId.isNotEmpty
        ? '$origin#/citizen/consultation/${Uri.encodeComponent(widget.title)}?poll=${Uri.encodeQueryComponent(pollId)}'
        : '$origin#/citizen/consultations';
    Clipboard.setData(
      ClipboardData(text: 'Donnez votre avis sur « ${widget.title} » : $link'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien de la consultation copié.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final questions = _questions;
    final poll = _poll;

    Widget content;
    if (_isLoading) {
      content = const _StatusCard(
        icon: Icons.hourglass_top_rounded,
        title: 'Chargement du questionnaire',
        message: 'Vérification sécurisée de votre code citoyen en cours…',
      );
    } else if (poll == null || questions.isEmpty) {
      content = _StatusCard(
        icon: Icons.error_outline_rounded,
        title: 'Consultation indisponible',
        message: _errorMessage ??
            'Cette consultation n’est plus disponible pour votre commune.',
        actionLabel: 'Retour aux consultations',
        onPressed: () => Navigator.of(context).pushReplacementNamed(
          '/citizen/consultations',
          arguments: {'session': session},
        ),
      );
    } else if (poll.hasVoted) {
      content = _StatusCard(
        icon: Icons.verified_rounded,
        title: 'Merci pour votre participation',
        message:
            'Votre réponse à cette consultation a déjà été enregistrée de manière anonyme.',
        actionLabel: 'Retour aux consultations',
        onPressed: () => Navigator.of(context).pushReplacementNamed(
          '/citizen/consultations',
          arguments: {'session': session},
        ),
      );
    } else {
      final question = questions[_stepIndex];
      final selected = _answers[question.id] ?? const <String>{};
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Étape ${_stepIndex + 1} sur ${questions.length}',
            style: const TextStyle(
              color: CitizenDesignTokens.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (_stepIndex + 1) / questions.length,
              minHeight: 8,
              backgroundColor: CitizenDesignTokens.skyBlue,
              color: CitizenDesignTokens.primaryBlue,
            ),
          ),
          const SizedBox(height: 22),
          _QuestionCard(
            stepNumber: _stepIndex + 1,
            question: question,
            selectedOptionIds: selected,
            enabled: _canContinue && !_isSubmitting,
            isSubmitting: _isSubmitting,
            isLastStep: _stepIndex == questions.length - 1,
            onToggle: (optionId) => _toggleOption(question, optionId),
            onContinue: _goNext,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              bottom: false,
              child: ColoredBox(
                color: CitizenDesignTokens.background,
                child: Column(
                  children: [
                    CitizenHeader(
                      title: widget.title,
                      trailing: IconButton(
                        tooltip: 'Partager',
                        onPressed: _shareConsultation,
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
                        child: content,
                      ),
                    ),
                    CitizenBottomNav(
                      activeTab: CitizenNavTab.opinion,
                      onTabSelected: (tab) => CitizenNavigation.open(
                        context,
                        tab,
                        session: session,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.stepNumber,
    required this.question,
    required this.selectedOptionIds,
    required this.enabled,
    required this.isSubmitting,
    required this.isLastStep,
    required this.onToggle,
    required this.onContinue,
  });

  final int stepNumber;
  final EligiblePollQuestion question;
  final Set<String> selectedOptionIds;
  final bool enabled;
  final bool isSubmitting;
  final bool isLastStep;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final subtitle = question.subtitle.isNotEmpty
        ? question.subtitle
        : question.multiple
            ? 'Vous pouvez choisir plusieurs réponses'
            : 'Sélectionnez une réponse';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: CitizenDesignTokens.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$stepNumber. ${question.title}',
            style: const TextStyle(
              color: CitizenDesignTokens.textDark,
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: CitizenDesignTokens.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          for (final option in question.options)
            _QuestionOptionTile(
              label: option.label,
              icon: pollIconForSlug(option.icon) ?? Icons.circle_outlined,
              illustrationAsset: pollIllustrationForSlug(option.icon),
              selected: selectedOptionIds.contains(option.id),
              onTap: () => onToggle(option.id),
            ),
          const SizedBox(height: 8),
          _PrimaryActionButton(
            key: const ValueKey('citizenVoteContinueButton'),
            enabled: enabled,
            label: isSubmitting
                ? 'Enregistrement…'
                : isLastStep
                    ? 'Confirmer mon choix'
                    : 'Question suivante',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _QuestionOptionTile extends StatelessWidget {
  const _QuestionOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.illustrationAsset,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? illustrationAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          key: ValueKey('pollOption_$label'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: selected
                  ? CitizenDesignTokens.skyBlue
                  : CitizenDesignTokens.lightBlue,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? CitizenDesignTokens.primaryBlue
                    : CitizenDesignTokens.cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: illustrationAsset != null
                      ? SvgPicture.asset(illustrationAsset!)
                      : Icon(
                          icon,
                          color: CitizenDesignTokens.primaryBlue,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: CitizenDesignTokens.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected
                        ? CitizenDesignTokens.primaryBlue
                        : Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: selected
                          ? CitizenDesignTokens.primaryBlue
                          : const Color(0xFFB8CBDD),
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    super.key,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: CitizenDesignTokens.yellowStrong,
          disabledBackgroundColor: CitizenDesignTokens.cardBorder,
          foregroundColor: CitizenDesignTokens.deepBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: CitizenDesignTokens.cardDecoration,
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: CitizenDesignTokens.skyBlue,
            child: Icon(
              icon,
              color: CitizenDesignTokens.primaryBlue,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CitizenDesignTokens.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CitizenDesignTokens.textMuted,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 20),
            _PrimaryActionButton(
              enabled: true,
              label: actionLabel!,
              onPressed: onPressed!,
            ),
          ],
        ],
      ),
    );
  }
}

class _VoteConfirmationPage extends StatelessWidget {
  const _VoteConfirmationPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final session = CitizenPublicAccessService.instance.currentSession;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              bottom: false,
              child: ColoredBox(
                color: CitizenDesignTokens.background,
                child: Column(
                  children: [
                    CitizenHeader(
                      title: 'Réponse enregistrée',
                      showBack: false,
                      trailing: IconButton(
                        tooltip: 'Retour à l’accueil',
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(
                          '/citizen/home',
                          (route) => false,
                          arguments: {'session': session},
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(22),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: CitizenDesignTokens.cardDecoration,
                            child: Column(
                              children: [
                                const CircleAvatar(
                                  radius: 42,
                                  backgroundColor: CitizenDesignTokens.skyBlue,
                                  child: Icon(
                                    Icons.verified_rounded,
                                    color: CitizenDesignTokens.success,
                                    size: 48,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Votre réponse a bien été enregistrée.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: CitizenDesignTokens.textDark,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Merci d’avoir participé à « $title ». Votre vote est anonyme et définitif.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: CitizenDesignTokens.textMuted,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _PrimaryActionButton(
                                  key: const ValueKey(
                                    'voteConfirmationConsultationsButton',
                                  ),
                                  enabled: true,
                                  label: 'Retour aux consultations',
                                  onPressed: () => Navigator.of(context)
                                      .pushNamedAndRemoveUntil(
                                    '/citizen/consultations',
                                    (route) => false,
                                    arguments: {'session': session},
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  key: const ValueKey(
                                    'voteConfirmationHomeButton',
                                  ),
                                  onPressed: () => Navigator.of(context)
                                      .pushNamedAndRemoveUntil(
                                    '/citizen/home',
                                    (route) => false,
                                    arguments: {'session': session},
                                  ),
                                  child: const Text('Retour à l’accueil'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    CitizenBottomNav(
                      activeTab: CitizenNavTab.opinion,
                      onTabSelected: (tab) => CitizenNavigation.open(
                        context,
                        tab,
                        session: session,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
