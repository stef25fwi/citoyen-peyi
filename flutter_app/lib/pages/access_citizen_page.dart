import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/citizen_commune_store.dart';
import '../services/citizen_public_access_service.dart';
import '../services/new_poll_badge_service.dart';
import '../services/push_notification_service.dart';
import '../services/vote_access_service.dart';
import '../theme/citoyen_theme.dart';
import '../widgets/public_bottom_nav.dart';
import 'legal_page.dart';

class AccessCitizenPage extends StatefulWidget {
  const AccessCitizenPage({
    super.key,
    this.initialCode,
    this.voteAccessService,
    this.persistSession,
  });

  /// Code citoyen prerempli (issu d'un QR scanne : `/#/access?code=...`).
  final String? initialCode;

  /// Dépendances injectables pour tester séparément la validation et les
  /// opérations secondaires exécutées après une connexion réussie.
  final VoteAccessService? voteAccessService;
  final Future<void> Function(CitizenPublicAccessSession session)?
      persistSession;

  static const routeName = '/access-citizen';
  static const legalTermsAcceptedKey = 'citoyen_peyi_legal_terms_accepted_v1';

  @override
  State<AccessCitizenPage> createState() => _AccessCitizenPageState();
}

class _AccessCitizenPageState extends State<AccessCitizenPage> {
  final TextEditingController _codeController = TextEditingController();

  bool hasReadLegalTerms = false;
  bool hasAcceptedLegalTerms = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _canValidate => hasAcceptedLegalTerms && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    final prefilled = widget.initialCode?.trim();
    if (prefilled != null && prefilled.isNotEmpty) {
      _codeController.text = prefilled.toUpperCase();
    }
    NewPollBadgeService.instance.markAllSeen();
    _loadStoredLegalAcceptance();
    _resumeCitizenSessionIfAvailable();
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
      if (accepted) {
        hasReadLegalTerms = true;
      }
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
      validation =
          await (widget.voteAccessService ?? VoteAccessService.instance)
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

  void _resumeCitizenSessionIfAvailable() {
    final session = CitizenPublicAccessService.instance.currentSession;
    if (session == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/citizen/welcome',
        (route) => false,
        arguments: {'session': session},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const _AccessBackground(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          topPadding + 26,
                          24,
                          18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _AccessHeroHeader(),
                            const SizedBox(height: 24),
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
                              onCodeChanged: () =>
                                  setState(() => _errorMessage = null),
                              onSubmit: _validateCitizenCode,
                            ),
                            const SizedBox(height: 14),
                            const _FooterNote(),
                          ],
                        ),
                      ),
                    ),
                    const PublicBottomNav(currentTab: PublicTab.vote),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessBackground extends StatelessWidget {
  const _AccessBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE5F8FF),
            Color(0xFFF4FCFF),
            Colors.white,
          ],
          stops: [0.0, 0.38, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -44,
            top: 76,
            child: Container(
              width: 142,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(90),
              ),
            ),
          ),
          Positioned(
            right: -52,
            top: 46,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: cpBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -18,
            top: 78,
            child: Opacity(
              opacity: 0.34,
              child: CustomPaint(
                size: const Size(100, 132),
                painter: _DotGridPainter(),
              ),
            ),
          ),
          Positioned(
            right: 22,
            top: 112,
            child: IgnorePointer(
              child: _ShieldWatermark(),
            ),
          ),
          Positioned(
            left: -120,
            bottom: 88,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: cpBlue.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldWatermark extends StatelessWidget {
  const _ShieldWatermark();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 58,
          color: cpBlueDark.withValues(alpha: 0.96),
        ),
        Icon(
          Icons.lock_rounded,
          size: 17,
          color: cpBlueDark.withValues(alpha: 0.38),
        ),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = cpBlue.withValues(alpha: 0.36);
    const spacing = 10.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.25, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccessHeroHeader extends StatelessWidget {
  const _AccessHeroHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AccessLogoHeader(),
        const SizedBox(height: 30),
        Text(
          'Accès citoyen',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF082E69),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Entrez votre code pour participer anonymement.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF5E6E83),
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            height: 1.18,
          ),
        ),
      ],
    );
  }
}

class _AccessLogoHeader extends StatelessWidget {
  const _AccessLogoHeader();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 248,
        height: 70,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F5B9D).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Semantics(
          label: 'Citoyen Peyi',
          image: true,
          child: Image.asset(
            cpLogoPath,
            height: 54,
            fit: BoxFit.contain,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EEF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2D55).withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Code citoyen',
            style: TextStyle(
              color: const Color(0xFF07356F),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 10),
          _CodeCitizenField(
            controller: codeController,
            enabled: !isSubmitting,
            onChanged: onCodeChanged,
            onSubmit: onSubmit,
          ),
          const SizedBox(height: 13),
          const _ConfidentialityBox(),
          const SizedBox(height: 14),
          _LegalTermsConsentPanel(
            hasReadLegalTerms: hasReadLegalTerms,
            hasAcceptedLegalTerms: hasAcceptedLegalTerms,
            onReadToEnd: onLegalTermsRead,
            onAcceptedChanged: onTermsChanged,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(
                color: const Color(0xFFB42318),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 18),
          _SubmitButton(
            isSubmitting: isSubmitting,
            canValidate: canValidate,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _CodeCitizenField extends StatelessWidget {
  const _CodeCitizenField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: cpBlueDark, width: 2.2),
    );

    return Container(
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cpBlueDark.withValues(alpha: 0.14),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        enableSuggestions: false,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          color: const Color(0xFF0B2D5C),
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: 0.4,
        ),
        decoration: InputDecoration(
          hintText: 'Saisissez votre code citoyen',
          hintStyle: TextStyle(
            color: const Color(0xFFA3AFC2),
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
          ),
          prefixIcon:
              const Icon(Icons.key_rounded, color: cpBlueDark, size: 31),
          prefixIconConstraints: const BoxConstraints(minWidth: 62),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          border: fieldBorder,
          enabledBorder: fieldBorder,
          focusedBorder: fieldBorder.copyWith(
            borderSide: const BorderSide(color: cpBlueDark, width: 2.6),
          ),
          disabledBorder: fieldBorder.copyWith(
            borderSide: const BorderSide(color: Color(0xFFB7D9F9), width: 2),
          ),
        ),
        onChanged: (_) => onChanged(),
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

class _ConfidentialityBox extends StatelessWidget {
  const _ConfidentialityBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD3E9FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: cpBlueDark, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Participation confidentielle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF08356F),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Vos réponses restent anonymes.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF63748A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalTermsConsentPanel extends StatelessWidget {
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

  void _openLegalPage(BuildContext context) {
    onReadToEnd();
    Navigator.of(context).pushNamed(LegalPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final readLabel = hasReadLegalTerms
        ? 'Lecture effectuée'
        : 'Lire les conditions pour accepter';
    final readColor = hasReadLegalTerms ? const Color(0xFF15A06F) : cpTextMuted;

    return Container(
      key: const ValueKey('accessCitizenLegalPill'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F6),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFDDEBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => _openLegalPage(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.balance_rounded,
                    color: cpBlueDark,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CGU, confidentialité et anonymat',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF08356F),
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          letterSpacing: -0.25,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: readColor,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              readLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: readColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF08356F),
                  size: 31,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: cpBlueDark,
              ),
              onPressed: () => _openLegalPage(context),
              child: Text(
                'Lire les conditions',
                style: TextStyle(
                  color: cpBlueDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          Divider(
            height: 16,
            color: const Color(0xFFD1DDD9).withValues(alpha: 0.9),
          ),
          _TermsAcceptanceRow(
            hasAcceptedLegalTerms: hasAcceptedLegalTerms,
            onChanged: (accepted) {
              if (accepted) onReadToEnd();
              onAcceptedChanged(accepted);
            },
          ),
        ],
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
    return Semantics(
      button: true,
      checked: hasAcceptedLegalTerms,
      label: 'J’ai lu et j’accepte les conditions d’utilisation.',
      child: InkWell(
        key: const ValueKey('accessCitizenTermsAcceptance'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!hasAcceptedLegalTerms),
        child: Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasAcceptedLegalTerms ? cpBlueDark : Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: hasAcceptedLegalTerms
                        ? cpBlueDark
                        : const Color(0xFFBFD2E4),
                    width: 1.4,
                  ),
                  boxShadow: hasAcceptedLegalTerms
                      ? [
                          BoxShadow(
                            color: cpBlueDark.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: hasAcceptedLegalTerms
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 25)
                    : null,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  'J’ai lu et j’accepte les conditions d’utilisation.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF0A2E5F),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.6,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSubmitting,
    required this.canValidate,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final bool canValidate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final enabled = canValidate;

    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE565),
                  cpYellow,
                  cpYellowStrong,
                ],
              )
            : null,
        color: enabled ? null : const Color(0xFFE5E7EB),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: cpYellowStrong.withValues(alpha: 0.38),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.85),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: enabled ? onSubmit : null,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSubmitting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cpBlueDark,
                    ),
                  )
                else
                  Icon(Icons.lock_outline_rounded,
                      size: 25,
                      color: enabled ? cpBlueDark : const Color(0xFF94A3B8)),
                const SizedBox(width: 13),
                Flexible(
                  child: Text(
                    'Valider mon code citoyen',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enabled ? cpBlueDark : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.25,
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

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user_outlined, color: cpBlueDark, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Plateforme de consultation citoyenne anonyme',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cpBlueDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}
