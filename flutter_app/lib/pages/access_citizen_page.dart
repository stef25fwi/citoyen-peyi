import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/citizen_commune_store.dart';
import '../services/citizen_public_access_service.dart';
import '../services/new_poll_badge_service.dart';
import '../services/push_notification_service.dart';
import '../services/vote_access_service.dart';
import '../theme/citoyen_theme.dart';
import '../widgets/debug_log_viewer.dart';
import '../widgets/public_bottom_nav.dart';
import 'legal_page.dart';

class AccessCitizenPage extends StatefulWidget {
  const AccessCitizenPage({super.key, this.initialCode});

  /// Code citoyen prerempli (issu d'un QR scanne : `/#/access?code=...`).
  final String? initialCode;

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

  bool get _canValidate =>
      hasAcceptedLegalTerms &&
      _codeController.text.trim().isNotEmpty &&
      !_isSubmitting;

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

    // Normalisation canonique (le backend hache en trim().toUpperCase()) : evite
    // les echecs dus a une casse differente et garde une session coherente.
    final rawCode = _codeController.text.trim().toUpperCase();
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

      await CitizenPublicAccessService.instance.saveSession(session);

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

      Navigator.of(context).pushNamed(
        '/citizen/welcome',
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

  void _resumeCitizenSessionIfAvailable() {
    final session = CitizenPublicAccessService.instance.currentSession;
    if (session == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/citizen/welcome',
        (route) => false,
        arguments: {'session': session},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _AccessBackground(),
          Positioned(
            top: 6,
            right: 6,
            child: SafeArea(child: DebugLogButton(label: '')),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _AccessLogoHeader(),
                            const SizedBox(height: 26),
                            Text(
                              'Accès citoyen',
                              style: GoogleFonts.inter(
                                color: cpTextDark,
                                fontSize: isCompact(context) ? 30 : 36,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Entrez votre code pour participer anonymement.',
                              style: GoogleFonts.inter(
                                color: cpTextMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 22),
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
                            const SizedBox(height: 20),
                            const _FooterNote(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const PublicBottomNav(currentTab: PublicTab.vote),
              ],
            ),
          ),
        ],
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
            Color(0xFFEAF8FF),
            Color(0xFFF3FBFF),
            Colors.white,
          ],
          stops: [0.0, 0.35, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -140,
            bottom: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: cpBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(180),
              ),
            ),
          ),
          Positioned(
            right: -80,
            top: 40,
            child: Opacity(
              opacity: 0.5,
              child: CustomPaint(
                size: const Size(180, 180),
                painter: _DotGridPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = cpBlue.withValues(alpha: 0.28);
    const spacing = 16.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccessLogoHeader extends StatelessWidget {
  const _AccessLogoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            height: 104,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Semantics(
              label: 'Citoyen Peyi',
              image: true,
              child: Image.asset(
                cpLogoPath,
                height: 58,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Icon(Icons.shield_outlined, color: cpBlueDark, size: 26),
                Positioned(
                  bottom: 10,
                  right: 11,
                  child: Icon(Icons.lock_rounded,
                      color: cpBlueDark, size: 12),
                ),
              ],
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Code citoyen',
            style: GoogleFonts.inter(
              color: cpTextDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: codeController,
            enabled: !isSubmitting,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            // Un code d'acces est sensible : on empeche le clavier de le
            // memoriser (suggestions/dictionnaire) et l'autocorrection de le
            // deformer silencieusement (source classique de "code invalide").
            autocorrect: false,
            enableSuggestions: false,
            style: GoogleFonts.inter(
              color: cpTextDark,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Saisissez votre code citoyen',
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF9AA6B8),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(Icons.key_rounded, color: cpBlueDark),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: cpBlue, width: 1.6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: cpBlue, width: 1.6),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: cpBlueDark, width: 2),
              ),
            ),
            onChanged: (_) => onCodeChanged(),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 16),
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
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w600,
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

class _ConfidentialityBox extends StatelessWidget {
  const _ConfidentialityBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cpBlueSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: cpBlueDark, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participation confidentielle',
                  style: GoogleFonts.inter(
                    color: cpTextDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vos réponses restent anonymes.',
                  style: GoogleFonts.inter(
                    color: cpTextMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
  State<_LegalTermsConsentPanel> createState() =>
      _LegalTermsConsentPanelState();
}

class _LegalTermsConsentPanelState extends State<_LegalTermsConsentPanel> {
  final _scrollController = ScrollController();
  late bool _expanded = !widget.hasReadLegalTerms;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  @override
  void didUpdateWidget(covariant _LegalTermsConsentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hasReadLegalTerms && widget.hasReadLegalTerms) {
      // La lecture vient de se terminer : on replie le panneau pour ne
      // garder que le resume + la case d'acceptation, comme sur la
      // maquette.
      setState(() => _expanded = false);
    }
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

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
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
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _toggleExpanded,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.balance_rounded,
                    color: cpBlueDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'CGU, confidentialité et anonymat',
                    style: GoogleFonts.inter(
                      color: cpTextDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: cpTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (hasRead) ...[
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A), size: 16),
                const SizedBox(width: 6),
                // Flexible (pas Text nu) : sur petit ecran, "Lecture
                // effectuee" + le lien "Lire les conditions" peuvent
                // depasser la largeur disponible (RenderFlex overflow).
                Flexible(
                  child: Text(
                    'Lecture effectuée',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    'Faites défiler le texte jusqu’à la fin pour accepter',
                    style: GoogleFonts.inter(
                      color: cpTextMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Spacer(),
              GestureDetector(
                onTap: _toggleExpanded,
                child: Text(
                  'Lire les conditions',
                  style: GoogleFonts.inter(
                    color: cpBlueDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Divider(color: const Color(0xFFB6ECE1).withValues(alpha: 0.8)),
            const SizedBox(height: 8),
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
                      style: GoogleFonts.inter(
                        color: const Color(0xFF334155),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!hasRead) ...[
              const SizedBox(height: 8),
              Text(
                'La case d’acceptation apparaîtra à la fin du texte.',
                style: GoogleFonts.inter(
                  color: cpTextMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
          if (hasRead) ...[
            const SizedBox(height: 10),
            Divider(color: const Color(0xFFB6ECE1).withValues(alpha: 0.8)),
            const SizedBox(height: 6),
            _TermsAcceptanceRow(
              hasAcceptedLegalTerms: widget.hasAcceptedLegalTerms,
              onChanged: widget.onAcceptedChanged,
            ),
          ],
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: hasAcceptedLegalTerms,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: cpBlueDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'J’ai lu et j’accepte les conditions d’utilisation.',
                style: GoogleFonts.inter(
                  color: cpTextDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ],
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
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE875),
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
                  blurRadius: 20,
                  offset: const Offset(0, 10),
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
                  Icon(Icons.lock_rounded,
                      color: enabled ? cpBlueDark : const Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Text(
                  'Valider mon code citoyen',
                  style: GoogleFonts.inter(
                    color: enabled ? cpBlueDark : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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
            style: GoogleFonts.inter(
              color: cpBlueDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
