from __future__ import annotations

import re
from pathlib import Path

PATH = Path('flutter_app/lib/pages/access_citizen_page.dart')

CONSTRUCTOR_OLD = "const AccessCitizenPage({super.key, this.initialCode});"
CONSTRUCTOR_NEW = """const AccessCitizenPage({
    super.key,
    this.initialCode,
    this.voteAccessService,
    this.persistSession,
  });"""

FIELDS_MARKER = """  final String? initialCode;
"""
FIELDS_REPLACEMENT = """  final String? initialCode;

  /// Dépendances injectables pour tester séparément la validation et les
  /// opérations secondaires exécutées après une connexion réussie.
  final VoteAccessService? voteAccessService;
  final Future<void> Function(CitizenPublicAccessSession session)?
      persistSession;
"""

METHOD_REPLACEMENT = r'''  Future<void> _validateCitizenCode() async {
    if (!hasAcceptedLegalTerms) {
      _showSnack(
          'Veuillez accepter les CGU avant de valider votre code citoyen.');
      return;
    }

    final rawCode = _codeController.text.trim().toUpperCase();
    if (rawCode.isEmpty) {
      _showSnack('Veuillez saisir votre code citoyen.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    late final VoteAccessValidationResult validation;
    try {
      validation = await (widget.voteAccessService ?? VoteAccessService.instance)
          .validateCode(rawCode);
    } on VoteAccessException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSubmitting = false;
      });
      return;
    } catch (error, stackTrace) {
      debugPrint('[CitizenAccess] code validation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Validation indisponible. Réessayez plus tard.';
        _isSubmitting = false;
      });
      return;
    }

    if (!mounted) return;

    late final CitizenPublicAccessSession session;
    try {
      final sessionFromFirestore =
          await CitizenPublicAccessService.instance.openAccess(rawCode);
      session = sessionFromFirestore ??
          CitizenPublicAccessService.instance.sessionFromValidation(
            rawCode: rawCode,
            validation: validation,
          );
    } catch (error, stackTrace) {
      debugPrint('[CitizenAccess] session creation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Code validé, mais l’espace citoyen n’a pas pu être ouvert.';
        _isSubmitting = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.of(context).pushNamed(
      '/citizen/welcome',
      arguments: {'session': session},
    );

    // La validation est déjà réussie et la session est active en mémoire.
    // Les écritures locales et l’abonnement aux notifications ne doivent
    // jamais transformer cette réussite en faux message d’erreur.
    unawaited(_completeCitizenLogin(rawCode: rawCode, session: session));
  }

  Future<void> _completeCitizenLogin({
    required String rawCode,
    required CitizenPublicAccessSession session,
  }) async {
    await _runPostLoginStep('save session', () async {
      final persistSession = widget.persistSession;
      if (persistSession != null) {
        await persistSession(session);
      } else {
        await CitizenPublicAccessService.instance.saveSession(session);
      }
    });
    await _runPostLoginStep(
      'save commune',
      () => CitizenCommuneStore.instance.save(
        communeId: session.communeId,
        communeName: session.communeName,
      ),
    );
    await _runPostLoginStep(
      'start notification badge',
      NewPollBadgeService.instance.startListening,
    );
    await _runPostLoginStep(
      'mark notifications seen',
      NewPollBadgeService.instance.markAllSeen,
    );
    await _runPostLoginStep(
      'register push notifications',
      () => PushNotificationService.instance.registerForCitizenCommune(
        rawCode: rawCode,
        communeId: session.communeId,
        communeName: session.communeName,
      ),
    );
  }

  Future<void> _runPostLoginStep(
    String label,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('[CitizenAccess] post-login $label failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _resumeCitizenSessionIfAvailable()'''


def main() -> None:
    text = PATH.read_text(encoding='utf-8')

    if CONSTRUCTOR_OLD in text:
        text = text.replace(CONSTRUCTOR_OLD, CONSTRUCTOR_NEW, 1)
    elif 'this.voteAccessService' not in text:
        raise SystemExit('AccessCitizenPage constructor not found')

    if 'final VoteAccessService? voteAccessService;' not in text:
        if FIELDS_MARKER not in text:
            raise SystemExit('AccessCitizenPage fields marker not found')
        text = text.replace(FIELDS_MARKER, FIELDS_REPLACEMENT, 1)

    if '_completeCitizenLogin' not in text:
        pattern = re.compile(
            r"  Future<void> _validateCitizenCode\(\) async \{.*?\n  void _resumeCitizenSessionIfAvailable\(\)",
            re.DOTALL,
        )
        text, count = pattern.subn(METHOD_REPLACEMENT, text, count=1)
        if count != 1:
            raise SystemExit('Citizen validation method not found')

    PATH.write_text(text, encoding='utf-8')


if __name__ == '__main__':
    main()
