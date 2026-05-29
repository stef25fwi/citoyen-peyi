import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/citizen_public_access_service.dart';
import '../services/new_poll_badge_service.dart';
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
  static const _background = Color(0xFFF7F4EA);
  static const _deepGreen = Color(0xFF123C2F);
  static const _textDark = Color(0xFF263A33);
  static const _mutedText = Color(0xFF627169);

  final TextEditingController _codeController = TextEditingController();

  bool hasOpenedLegalPage = false;
  bool hasAcceptedLegalTerms = false;
  bool _acceptedFromDevice = false;
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
      _acceptedFromDevice = true;
    });
  }

  Future<void> _setAcceptedLegalTerms(bool accepted) async {
    setState(() {
      hasAcceptedLegalTerms = accepted;
      _acceptedFromDevice = accepted && _acceptedFromDevice;
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
        foregroundColor: _deepGreen,
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
                      color: _deepGreen,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Avant de participer, veuillez consulter les informations légales et confirmer la lecture des conditions d’utilisation.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _textDark,
                      height: 1.42,
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
                    acceptedFromDevice: _acceptedFromDevice,
                    onTermsTap: _handleTermsTap,
                    onCodeChanged: () => setState(() => _errorMessage = null),
                    onSubmit: _validateCitizenCode,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Citoyen Peyi garantit une consultation citoyenne confidentielle. Les réponses sont exploitées sous forme statistique ou agrégée.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _mutedText,
                      height: 1.45,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF123C2F),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Votre participation est traitée de manière confidentielle. Le code citoyen permet de sécuriser l’accès à la consultation et de limiter les participations multiples.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF263A33),
                  height: 1.45,
                ),
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
      label: 'Informations légales, consulter les CGU',
      child: Material(
        color: const Color(0xFFFFF3BF),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: const ValueKey('accessCitizenLegalPill'),
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6B93F)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.balance_rounded,
                    color: Color(0xFF705200),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations légales',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF263A33),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CGU, confidentialité, anonymat et données personnelles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5D4A11),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF705200),
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
    required this.acceptedFromDevice,
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
  final bool acceptedFromDevice;
  final VoidCallback onTermsTap;
  final VoidCallback onCodeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
                hintText: 'Exemple : CP-2026-XXXX',
                helperText:
                    'Ce code permet de vérifier votre accès sans afficher publiquement votre identité.',
                filled: true,
                fillColor: const Color(0xFFFAFBF7),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFD7E0D8)),
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
            const SizedBox(height: 8),
            if (acceptedFromDevice)
              Text(
                'CGU déjà acceptées sur cet appareil.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF256E4A),
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                hasOpenedLegalPage
                    ? 'La validation du code est disponible après acceptation des CGU.'
                    : 'La validation sera disponible après consultation et acceptation des CGU.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF627169),
                  height: 1.35,
                ),
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
                  backgroundColor: const Color(0xFF123C2F),
                  disabledBackgroundColor: const Color(0xFFD6DDD8),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF728078),
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
                label: Text(
                  isSubmitting ? 'Vérification...' : 'Valider mon code citoyen',
                ),
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
      label:
          'Je confirme avoir consulté et accepté les conditions générales d’utilisation.',
      child: Material(
        color: hasOpenedLegalPage
            ? const Color(0xFFF8FBF9)
            : const Color(0xFFF1F2EF),
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
                    ? const Color(0xFFC8D6CE)
                    : const Color(0xFFD8DED9),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: hasAcceptedLegalTerms,
                  onChanged: hasOpenedLegalPage ? (_) => onTap() : null,
                  activeColor: const Color(0xFF123C2F),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: Text(
                      'Je confirme avoir consulté et accepté les conditions générales d’utilisation.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF263A33),
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
