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

  bool hasOpenedLegalPage = false;
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
      hasOpenedLegalPage = true;
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

  Future<void> _openLegalPage() async {
    setState(() {
      hasOpenedLegalPage = true;
      _errorMessage = null;
    });
    await Navigator.of(context).pushNamed(LegalPage.routeName);
  }

  Future<void> _handleTermsTap() async {
    if (!hasOpenedLegalPage) {
      _showSnack(
        'Veuillez d’abord consulter les informations légales avant de continuer.',
      );
      return;
    }
    await _setAcceptedLegalTerms(!hasAcceptedLegalTerms);
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
                  _LegalInformationPill(onTap: _openLegalPage),
                  const SizedBox(height: 14),
                  _AccessFormCard(
                    codeController: _codeController,
                    errorMessage: _errorMessage,
                    isSubmitting: _isSubmitting,
                    canValidate: _canValidate,
                    hasOpenedLegalPage: hasOpenedLegalPage,
                    hasAcceptedLegalTerms: hasAcceptedLegalTerms,
                    onTermsTap: _handleTermsTap,
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

class _LegalInformationPill extends StatelessWidget {
  const _LegalInformationPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label:
          'CGU, confidentialité et données personnelles, à consulter avant participation',
      child: Material(
        color: const Color(0xFFF0FDF9),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: const ValueKey('accessCitizenLegalPill'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB6ECE1)),
            ),
            child: Row(
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
                        'À consulter avant participation',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF0D73F2),
                ),
              ],
            ),
          ),
        ),
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
    required this.hasOpenedLegalPage,
    required this.hasAcceptedLegalTerms,
    required this.onTermsTap,
    required this.onCodeChanged,
    required this.onSubmit,
  });

  final TextEditingController codeController;
  final String? errorMessage;
  final bool isSubmitting;
  final bool canValidate;
  final bool hasOpenedLegalPage;
  final bool hasAcceptedLegalTerms;
  final VoidCallback onTermsTap;
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
            _TermsAcceptanceRow(
              hasOpenedLegalPage: hasOpenedLegalPage,
              hasAcceptedLegalTerms: hasAcceptedLegalTerms,
              onTap: onTermsTap,
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
    required this.hasOpenedLegalPage,
    required this.hasAcceptedLegalTerms,
    required this.onTap,
  });

  final bool hasOpenedLegalPage;
  final bool hasAcceptedLegalTerms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      checked: hasAcceptedLegalTerms,
      label: 'J’ai lu et j’accepte les conditions d’utilisation.',
      child: Material(
        color: hasOpenedLegalPage
            ? const Color(0xFFF0FDF9)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const ValueKey('accessCitizenTermsAcceptance'),
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasOpenedLegalPage
                    ? const Color(0xFFB6ECE1)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: hasAcceptedLegalTerms,
                  onChanged: hasOpenedLegalPage ? (_) => onTap() : null,
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
