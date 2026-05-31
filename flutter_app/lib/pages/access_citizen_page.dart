import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/citizen_commune_store.dart';
import '../services/citizen_public_access_service.dart';
import '../services/new_poll_badge_service.dart';
import '../services/push_notification_service.dart';
import '../services/vote_access_service.dart';
import '../widgets/public_bottom_nav.dart';
import 'legal_page.dart';

class AccessCitizenPage extends StatefulWidget {
  const AccessCitizenPage({super.key});

  static const routeName = '/access-citizen';
  static const legalTermsAcceptedKey = 'citoyen_peyi_legal_terms_accepted_v1';

  @override
  State<AccessCitizenPage> createState() => _AccessCitizenPageState();
}

class _AccessCitizenPageState extends State<AccessCitizenPage> {
  static const _background = Color(0xFFFFFFFF);
  static const _foreground = Color(0xFF0F172A);
  static const _mutedText = Color(0xFF64748B);

  final TextEditingController _codeController = TextEditingController();

  bool hasReadLegalTerms = false;
  bool hasAcceptedLegalTerms = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _canValidate =>
      hasAcceptedLegalTerms &&
      _codeController.text.trim().isNotEmpty &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    NewPollBadgeService.instance.markAllSeen();
    _loadStoredLegalAcceptance();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredLegalAcceptance() async {
    final preferences = await SharedPreferences.getInstance();
    final accepted =
        preferences.getBool(AccessCitizenPage.legalTermsAcceptedKey) ?? false;
    if (!mounted || !accepted) return;
    setState(() {
      hasReadLegalTerms = true;
      hasAcceptedLegalTerms = true;
    });
  }

  Future<void> _setAcceptedLegalTerms(bool accepted) async {
    setState(() {
      hasAcceptedLegalTerms = accepted;
      _errorMessage = null;
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      AccessCitizenPage.legalTermsAcceptedKey,
      accepted,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _markLegalTermsRead() {
    if (hasReadLegalTerms) return;
    setState(() {
      hasReadLegalTerms = true;
      _errorMessage = null;
    });
  }

  Future<void> _validateCitizenCode() async {
    if (!hasAcceptedLegalTerms) {
      _showSnack(
          'Veuillez accepter les CGU avant de valider votre code citoyen.');
      return;
    }

    final rawCode = _codeController.text.trim();
    if (rawCode.isEmpty) {
      _showSnack('Veuillez saisir votre code citoyen.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final validation = await VoteAccessService.instance.validateCode(rawCode);
      if (!mounted) return;

      final sessionFromFirestore =
          await CitizenPublicAccessService.instance.openAccess(rawCode);
      final session = sessionFromFirestore ??
          CitizenPublicAccessService.instance.sessionFromValidation(
            rawCode: rawCode,
            validation: validation,
          );
      if (!mounted) return;

      await CitizenCommuneStore.instance.save(
        communeId: session.communeId,
        communeName: session.communeName,
      );
      await NewPollBadgeService.instance.startListening();
      await NewPollBadgeService.instance.markAllSeen();
      if (!mounted) return;
      unawaited(PushNotificationService.instance.registerForCitizenCommune(
        rawCode: rawCode,
        communeId: session.communeId,
        communeName: session.communeName,
      ));

      setState(() => _isSubmitting = false);

      if (validation.eligiblePolls.length == 1) {
        final poll = validation.eligiblePolls.first;
        final routeCode = Uri.encodeComponent(session.accessCode);
        final routePollId = Uri.encodeQueryComponent(poll.pollId);
        Navigator.of(context).pushNamed('/vote/$routeCode?poll=$routePollId');
        return;
      }

      Navigator.of(context).pushNamed(
        '/citizen',
        arguments: {'session': session},
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
        _errorMessage = 'Validation indisponible. Réessayez plus tard.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _foreground,
        title: const Text('Accès citoyen'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour à l’accueil',
          onPressed: () => Navigator.of(context).pushNamed('/'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Accès citoyen',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: _foreground,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Entrez votre code citoyen pour participer anonymement.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _mutedText,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _ConfidentialityCard(theme: theme),
                  const SizedBox(height: 14),
                  _AccessFormCard(
                    codeController: _codeController,
                    errorMessage: _errorMessage,
                    isSubmitting: _isSubmitting,
                    canValidate: _canValidate,
                    hasReadLegalTerms: hasReadLegalTerms,
                    hasAcceptedLegalTerms: hasAcceptedLegalTerms,
                    onLegalTermsRead: _markLegalTermsRead,
                    onTermsChanged: (accepted) =>
                      unawaited(_setAcceptedLegalTerms(accepted)),
                    onCodeChanged: () => setState(() => _errorMessage = null),
                    onSubmit: _validateCitizenCode,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Plateforme de consultation citoyenne anonyme.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _mutedText,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const PublicBottomNav(currentTab: PublicTab.vote),
    );
  }
}

class _ConfidentialityCard extends StatelessWidget {
  const _ConfidentialityCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Color(0xFF0D73F2),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participation confidentielle',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Votre code sécurise l’accès et limite les participations multiples. Vos réponses sont exploitées uniquement sous forme statistique.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                      height: 1.32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalTermsConsentPanel extends StatefulWidget {
  const _LegalTermsConsentPanel({
    required this.hasReadLegalTerms,
    required this.hasAcceptedLegalTerms,
    required this.onReadToEnd,
    required this.onAcceptedChanged,
  });

  final bool hasReadLegalTerms;
  final bool hasAcceptedLegalTerms;
  final VoidCallback onReadToEnd;
  final ValueChanged<bool> onAcceptedChanged;

  @override
  State<_LegalTermsConsentPanel> createState() => _LegalTermsConsentPanelState();
}

class _LegalTermsConsentPanelState extends State<_LegalTermsConsentPanel> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (widget.hasReadLegalTerms || !_scrollController.hasClients) return;
    _checkScrollMetrics(_scrollController.position);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.hasReadLegalTerms) {
      _checkScrollMetrics(notification.metrics);
    }
    return false;
  }

  void _checkScrollMetrics(ScrollMetrics metrics) {
    if (metrics.maxScrollExtent <= 0 ||
        metrics.pixels >= metrics.maxScrollExtent - 8) {
      widget.onReadToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRead = widget.hasReadLegalTerms;

    return Container(
      key: const ValueKey('accessCitizenLegalPill'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB6ECE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.balance_rounded,
                  color: Color(0xFF0D73F2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CGU, confidentialité et données personnelles',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasRead
                          ? 'Lecture complète effectuée'
                          : 'Faites défiler le texte jusqu’à la fin pour accepter',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasRead
                            ? const Color(0xFF047857)
                            : const Color(0xFF64748B),
                        fontWeight: hasRead ? FontWeight.w700 : null,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 176,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  key: const ValueKey('accessCitizenLegalTermsScroll'),
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 12, 22, 12),
                  child: Text(
                    buildFullLegalDocumentText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF334155),
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (hasRead)
            _TermsAcceptanceRow(
              hasAcceptedLegalTerms: widget.hasAcceptedLegalTerms,
              onChanged: widget.onAcceptedChanged,
            )
          else
            Text(
              'La case d’acceptation apparaîtra à la fin du texte.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _AccessFormCard extends StatelessWidget {
  const _AccessFormCard({
    required this.codeController,
    required this.errorMessage,
    required this.isSubmitting,
    required this.canValidate,
    required this.hasReadLegalTerms,
    required this.hasAcceptedLegalTerms,
    required this.onLegalTermsRead,
    required this.onTermsChanged,
    required this.onCodeChanged,
    required this.onSubmit,
  });

  final TextEditingController codeController;
  final String? errorMessage;
  final bool isSubmitting;
  final bool canValidate;
  final bool hasReadLegalTerms;
  final bool hasAcceptedLegalTerms;
  final VoidCallback onLegalTermsRead;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onCodeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: codeController,
              enabled: !isSubmitting,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Code citoyen',
                hintText: 'Code citoyen',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              onChanged: (_) => onCodeChanged(),
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 14),
            _LegalTermsConsentPanel(
              hasReadLegalTerms: hasReadLegalTerms,
              hasAcceptedLegalTerms: hasAcceptedLegalTerms,
              onReadToEnd: onLegalTermsRead,
              onAcceptedChanged: onTermsChanged,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: canValidate ? onSubmit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D73F2),
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF64748B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_open_rounded),
                label: const Text('Valider mon code citoyen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsAcceptanceRow extends StatelessWidget {
  const _TermsAcceptanceRow({
    required this.hasAcceptedLegalTerms,
    required this.onChanged,
  });

  final bool hasAcceptedLegalTerms;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      checked: hasAcceptedLegalTerms,
      label: 'J’ai lu et j’accepte les conditions d’utilisation.',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const ValueKey('accessCitizenTermsAcceptance'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(!hasAcceptedLegalTerms),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasAcceptedLegalTerms
                    ? const Color(0xFFB6ECE1)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: hasAcceptedLegalTerms,
                  onChanged: (value) => onChanged(value ?? false),
                  activeColor: const Color(0xFF0D73F2),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: Text(
                      'J’ai lu et j’accepte les conditions d’utilisation.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
