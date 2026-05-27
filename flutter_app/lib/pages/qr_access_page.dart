import 'package:flutter/material.dart';

import '../services/citizen_public_access_service.dart';
import '../services/new_poll_badge_service.dart';
import '../services/vote_access_service.dart';
import '../widgets/public_bottom_nav.dart';

class QrAccessPage extends StatefulWidget {
  const QrAccessPage({super.key});

  @override
  State<QrAccessPage> createState() => _QrAccessPageState();
}

class _QrAccessPageState extends State<QrAccessPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    NewPollBadgeService.instance.markAllSeen();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _openAccess() async {
    final rawCode = _codeController.text.trim();
    if (rawCode.isEmpty) {
      if (mounted) {
        setState(() => _errorMessage = 'Code citoyen requis.');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Validation sécurisée côté backend.
      final validation = await VoteAccessService.instance.validateCode(rawCode);
      if (!mounted) return;

      // Charger la session "espace citoyen" depuis Firestore si accessible,
      // sinon construire la session directement depuis les données backend.
      final sessionFromFirestore = await CitizenPublicAccessService.instance.openAccess(rawCode);
      final session = sessionFromFirestore ??
          CitizenPublicAccessService.instance.sessionFromValidation(
            rawCode: rawCode,
            validation: validation,
          );
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      // Navigation: si une seule consultation eligible, on va directement voter.
      if (validation.eligiblePolls.length == 1) {
        final poll = validation.eligiblePolls.first;
        final routeCode = Uri.encodeComponent(session.accessCode);
        final routePollId = Uri.encodeQueryComponent(poll.pollId);
        Navigator.of(context).pushNamed(
          '/vote/$routeCode?poll=$routePollId',
        );
        return;
      }

      // Sinon, espace citoyen: liste des consultations disponibles.
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
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Accès citoyen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.qr_code_2_rounded, size: 64, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 20),
                Text('Accedez a votre espace citoyen', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  'Saisissez le code citoyen anonyme remis par l\'agent de mobilisation citoyenne ou collez l\'URL de votre QR.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF5A6573)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Validation sécurisée côté serveur. Votre identité ne sera pas enregistrée.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A6573)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextField(
                          controller: _codeController,
                          enabled: !_isSubmitting,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Ex : A1B2C3D4',
                            labelText: 'Code citoyen anonyme ou lien QR',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
                            ),
                          ),
                          onChanged: (_) => setState(() => _errorMessage = null),
                          onSubmitted: (_) => _openAccess(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFB42318)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting || _codeController.text.trim().isEmpty ? null : _openAccess,
                            icon: _isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.arrow_forward_rounded),
                            label: Text(_isSubmitting ? 'Verification...' : 'Acceder a mon espace citoyen'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const PublicBottomNav(currentTab: PublicTab.vote),
    );
  }
}

