import 'package:flutter/material.dart';

import '../../services/vote_access_service.dart';
import '../../widgets/poll_option_icons.dart';
import '../public_news_page.dart';
import '../public_results_page.dart';

class CitizenPollQuestionPage extends StatefulWidget {
  const CitizenPollQuestionPage({
    super.key,
    this.title = 'Aménagement des espaces publics',
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
  VoteAccessService get _voteAccessService =>
      widget.voteAccessService ?? VoteAccessService.instance;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  VoteAccessValidationResult? _validation;
  EligiblePollModel? _poll;
  int _stepIndex = 0;
  final Map<String, Set<String>> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadPoll();
  }

  Future<void> _loadPoll() async {
    final pollId = widget.pollId?.trim();
    final accessCode = widget.accessCode?.trim();
    if (pollId == null ||
        pollId.isEmpty ||
        accessCode == null ||
        accessCode.isEmpty) {
      // Pas de session citoyenne valide : le code d'acces reste obligatoire
      // pour voter, on redirige vers la saisie du code.
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
      final result =
          await _voteAccessService.validateCode(accessCode, pollId: pollId);
      EligiblePollModel? poll;
      for (final candidate in result.eligiblePolls) {
        if (candidate.pollId == pollId) {
          poll = candidate;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _validation = result;
        _poll = poll;
        _isLoading = false;
        _errorMessage =
            poll == null ? 'Cette consultation n\'est plus disponible.' : null;
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
        _errorMessage = 'Validation du code impossible. Réessayez plus tard.';
      });
    }
  }

  List<EligiblePollQuestion> get _questions =>
      _poll?.effectiveQuestions ?? const [];

  EligiblePollQuestion? get _currentQuestion {
    final questions = _questions;
    if (_stepIndex < 0 || _stepIndex >= questions.length) return null;
    return questions[_stepIndex];
  }

  bool get _canContinue {
    final question = _currentQuestion;
    if (question == null) return false;
    return _answers[question.id]?.isNotEmpty == true;
  }

  void _toggleOption(EligiblePollQuestion question, String optionId) {
    setState(() {
      final selected = _answers.putIfAbsent(question.id, () => <String>{});
      if (question.multiple) {
        if (selected.contains(optionId)) {
          selected.remove(optionId);
        } else {
          selected.add(optionId);
        }
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
    if (poll == null || validation == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final answers = _questions
        .map((question) => PollAnswer(
              questionId: question.id,
              optionIds: _answers[question.id]?.toList() ?? const [],
            ))
        .toList();

    try {
      await _voteAccessService.submitVote(
        accessToken:
            poll.accessToken.isNotEmpty ? poll.accessToken : validation.accessToken,
        pollId: poll.pollId,
        answers: answers,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _CitizenQuestionStepBridgePage(title: widget.title),
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
            'Réseau indisponible. Votre vote n\'a pas été enregistré.';
      });
    }
  }

  void _onNav(CitizenNavTab tab) {
    if (tab == CitizenNavTab.opinion) {
      Navigator.of(context).pushReplacementNamed('/citizen/consultations');
      return;
    }

    if (tab == CitizenNavTab.home) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/citizen/welcome',
        (route) => route.isFirst,
      );
      return;
    }

    if (tab == CitizenNavTab.news) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublicNewsPage()),
      );
      return;
    }

    if (tab == CitizenNavTab.results) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublicResultsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String headerTitle = _headerTitleFor(widget.title);
    final questions = _questions;
    final poll = _poll;

    Widget body;
    if (_isLoading) {
      body = const _StatusCard(
        icon: Icons.hourglass_top_rounded,
        title: 'Chargement du questionnaire',
        message: 'Vérification sécurisée de votre code citoyen en cours...',
      );
    } else if (poll == null || questions.isEmpty) {
      body = _StatusCard(
        icon: Icons.error_outline_rounded,
        title: 'Consultation indisponible',
        message: _errorMessage ??
            'Cette consultation n\'est plus disponible pour votre commune.',
        actionLabel: 'Retour aux consultations',
        onPressed: () => Navigator.of(context).pushReplacementNamed(
          '/citizen/consultations',
        ),
      );
    } else if (poll.hasVoted) {
      body = const _StatusCard(
        icon: Icons.verified_rounded,
        title: 'Merci pour votre participation',
        message:
            'Votre réponse à cette consultation a déjà été enregistrée de manière anonyme.',
      );
    } else {
      final question = questions[_stepIndex];
      final selected = _answers[question.id] ?? const <String>{};
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Étape ${_stepIndex + 1} sur ${questions.length}',
            style: const TextStyle(
              color: _CitizenColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_stepIndex + 1) / questions.length,
              minHeight: 8,
              backgroundColor: _CitizenColors.skyBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(
                _CitizenColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 26),
          _QuestionCard(
            stepNumber: _stepIndex + 1,
            question: question,
            selectedOptionIds: selected,
            canContinue: _canContinue,
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: _CitizenColors.background,
      body: _MobileFrame(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _CitizenHeader(
                title: headerTitle,
                trailing: IconButton(
                  tooltip: 'Partager',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partage à connecter.')),
                    );
                  },
                  icon: const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: body,
                ),
              ),
              _CitizenBottomNav(
                activeTab: CitizenNavTab.opinion,
                onTabSelected: _onNav,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _headerTitleFor(String title) {
    final normalized = title
        .replaceAll('Amenagement', 'Aménagement')
        .replaceAll('espaces publics', 'espaces publics');
    return normalized == 'Aménagement des espaces publics'
        ? 'Aménagement des\nespaces publics'
        : normalized;
  }
}

class _MobileFrame extends StatelessWidget {
  const _MobileFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: child,
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
      decoration: BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _CitizenColors.cardBorder),
        boxShadow: _CitizenColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              color: _CitizenColors.skyBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _CitizenColors.primaryBlue, size: 42),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _CitizenColors.textDark,
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _CitizenColors.textMuted,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 18),
            _YellowContinueButton(enabled: true, onPressed: onPressed!),
          ],
        ],
      ),
    );
  }
}

class _CitizenQuestionStepBridgePage extends StatelessWidget {
  const _CitizenQuestionStepBridgePage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CitizenColors.background,
      body: _MobileFrame(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              children: [
                _CitizenHeader(
                  title: 'Réponse\nenregistrée',
                  trailing: IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _CitizenColors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _CitizenColors.cardBorder),
                      boxShadow: _CitizenColors.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: const BoxDecoration(
                            color: _CitizenColors.skyBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: _CitizenColors.primaryBlue,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Votre réponse a bien été enregistrée.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _CitizenColors.textDark,
                            fontSize: 20,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Merci d\'avoir participé à "$title". Votre vote est anonyme et définitif.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _CitizenColors.textMuted,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _YellowContinueButton(
                          enabled: true,
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/citizen/consultations',
                              (route) => route.isFirst,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/citizen/home',
                              (route) => route.isFirst,
                            );
                          },
                          child: const Text(
                            'Retour à l’accueil citoyen',
                            style: TextStyle(
                              color: _CitizenColors.deepBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _CitizenBottomNav(
                  activeTab: CitizenNavTab.opinion,
                  onTabSelected: (tab) {
                    if (tab == CitizenNavTab.opinion) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/citizen/consultations',
                        (route) => route.isFirst,
                      );
                      return;
                    }
                    if (tab == CitizenNavTab.home) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/citizen/home',
                        (route) => route.isFirst,
                      );
                      return;
                    }
                    if (tab == CitizenNavTab.news) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublicNewsPage()),
                      );
                      return;
                    }
                    if (tab == CitizenNavTab.results) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublicResultsPage()),
                      );
                    }
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

class _CitizenColors {
  const _CitizenColors._();

  static const Color primaryBlue = Color(0xFF0075C9);
  static const Color deepBlue = Color(0xFF005CA8);
  static const Color skyBlue = Color(0xFFEAF8FF);
  static const Color lightBlue = Color(0xFFF2FAFF);
  static const Color yellowStrong = Color(0xFFFFDA29);
  static const Color textDark = Color(0xFF143B5A);
  static const Color textMuted = Color(0xFF607A94);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE3EEF6);
  static const Color background = Color(0xFFF6FCFF);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, deepBlue],
  );

  static List<BoxShadow> softShadow = const [
    BoxShadow(
      color: Color(0x1A0075C9),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}

class _CitizenHeader extends StatelessWidget {
  const _CitizenHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: _CitizenColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Retour',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 54),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null)
                Align(alignment: Alignment.centerRight, child: trailing!),
            ],
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
    required this.canContinue,
    required this.isSubmitting,
    required this.isLastStep,
    required this.onToggle,
    required this.onContinue,
  });

  final int stepNumber;
  final EligiblePollQuestion question;
  final Set<String> selectedOptionIds;
  final bool canContinue;
  final bool isSubmitting;
  final bool isLastStep;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final subtitle = question.subtitle.isNotEmpty
        ? question.subtitle
        : (question.multiple
            ? 'Vous pouvez choisir plusieurs réponses'
            : 'Sélectionnez une réponse');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CitizenColors.cardBorder),
        boxShadow: _CitizenColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$stepNumber. ${question.title}',
            style: const TextStyle(
              color: _CitizenColors.textDark,
              fontSize: 17,
              height: 1.18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: _CitizenColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          for (final option in question.options)
            _QuestionOptionTile(
              label: option.label,
              icon: pollIconForSlug(option.icon) ?? Icons.circle_outlined,
              selected: selectedOptionIds.contains(option.id),
              onTap: () => onToggle(option.id),
            ),
          const SizedBox(height: 18),
          _YellowContinueButton(
            enabled: canContinue && !isSubmitting,
            label: isSubmitting
                ? 'Enregistrement...'
                : (isLastStep ? 'Confirmer' : 'Suivant'),
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
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _CitizenColors.lightBlue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _CitizenColors.primaryBlue : _CitizenColors.cardBorder,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: _CitizenColors.skyBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _CitizenColors.primaryBlue, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _CitizenColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? _CitizenColors.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? _CitizenColors.primaryBlue : const Color(0xFFB8CBDD),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YellowContinueButton extends StatelessWidget {
  const _YellowContinueButton({
    required this.enabled,
    required this.onPressed,
    this.label = 'Suivant',
  });

  final bool enabled;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onPressed : null,
            child: Ink(
              height: 52,
              decoration: BoxDecoration(
                color: enabled ? _CitizenColors.yellowStrong : _CitizenColors.cardBorder,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _CitizenColors.deepBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: _CitizenColors.deepBlue,
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

enum CitizenNavTab { home, news, opinion, results }

class _CitizenBottomNav extends StatelessWidget {
  const _CitizenBottomNav({required this.activeTab, required this.onTabSelected});

  final CitizenNavTab activeTab;
  final ValueChanged<CitizenNavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: _CitizenColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0075C9),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          _BottomNavItem(tab: CitizenNavTab.home, activeTab: activeTab, icon: Icons.home_rounded, label: 'Accueil', onTap: onTabSelected),
          _BottomNavItem(tab: CitizenNavTab.news, activeTab: activeTab, icon: Icons.calendar_month_rounded, label: 'Actualités', onTap: onTabSelected),
          _BottomNavItem(tab: CitizenNavTab.opinion, activeTab: activeTab, icon: Icons.how_to_vote_rounded, label: 'Donner mon avis', onTap: onTabSelected),
          _BottomNavItem(tab: CitizenNavTab.results, activeTab: activeTab, icon: Icons.bar_chart_rounded, label: 'Résultats', onTap: onTabSelected),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.tab,
    required this.activeTab,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final CitizenNavTab tab;
  final CitizenNavTab activeTab;
  final IconData icon;
  final String label;
  final ValueChanged<CitizenNavTab> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = tab == activeTab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onTap(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? _CitizenColors.skyBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive ? _CitizenColors.primaryBlue : _CitizenColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? _CitizenColors.primaryBlue : _CitizenColors.textMuted,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
