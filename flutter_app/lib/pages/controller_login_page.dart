import 'package:flutter/material.dart';

import '../services/controller_auth_service.dart';
import '../theme/citizen_design_tokens.dart';

class ControllerLoginPage extends StatefulWidget {
  const ControllerLoginPage({super.key});

  @override
  State<ControllerLoginPage> createState() => _ControllerLoginPageState();
}

class _ControllerLoginPageState extends State<ControllerLoginPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || _codeController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await ControllerAuthService.instance
          .signInWithCode(_codeController.text);
      if (!mounted) return;

      final commune = result.session.commune?.name;
      final message = commune == null || commune.isEmpty
          ? 'Bienvenue, ${result.session.label ?? 'Agent de mobilisation citoyenne'}'
          : 'Bienvenue, ${result.session.label ?? 'Agent de mobilisation citoyenne'} · $commune';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pushReplacementNamed('/controleur');
    } on ControllerAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit =
        !_isSubmitting && _codeController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/'),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_turned_in_rounded,
              color: CitizenDesignTokens.primaryBlue,
              size: 22,
            ),
            SizedBox(width: CitizenDesignTokens.space8),
            Flexible(
              child: Text(
                'Espace agent de mobilisation citoyenne',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: CitizenDesignTokens.softBackgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(CitizenDesignTokens.space20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        (CitizenDesignTokens.space20 * 2),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Container(
                        padding:
                            const EdgeInsets.all(CitizenDesignTokens.space24),
                        decoration:
                            CitizenDesignTokens.elevatedCardDecoration,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: CitizenDesignTokens.surfaceBlue,
                                borderRadius: BorderRadius.circular(
                                  CitizenDesignTokens.radiusButton,
                                ),
                                border: Border.all(
                                  color: CitizenDesignTokens.cardBorder,
                                ),
                              ),
                              child: const Icon(
                                Icons.badge_outlined,
                                size: 30,
                                color: CitizenDesignTokens.primaryBlue,
                              ),
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space16),
                            Text(
                              'Connexion agent',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space8),
                            Text(
                              'Saisissez le code remis par votre administrateur pour accéder aux outils de mobilisation citoyenne.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: CitizenDesignTokens.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space24),
                            TextField(
                              controller: _codeController,
                              enabled: !_isSubmitting,
                              autofocus: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              maxLength: 24,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                letterSpacing: 1.2,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                hintText: 'Ex. A3F2B1C97D5E4B08',
                                prefixIcon: Icon(Icons.key_rounded),
                              ),
                              onChanged: (value) {
                                var normalized = value.toUpperCase();
                                if (normalized.startsWith('CTRL-')) {
                                  normalized = normalized.substring(5);
                                }
                                if (normalized != value) {
                                  _codeController.value =
                                      _codeController.value.copyWith(
                                    text: normalized,
                                    selection: TextSelection.collapsed(
                                      offset: normalized.length,
                                    ),
                                  );
                                }
                                setState(() {});
                              },
                              onSubmitted: (_) {
                                if (canSubmit) _submit();
                              },
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: canSubmit ? _submit : null,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: CitizenDesignTokens.white,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_forward_rounded),
                                label: Text(
                                  _isSubmitting
                                      ? 'Connexion en cours…'
                                      : 'Accéder à mon espace',
                                ),
                              ),
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space12),
                            Text(
                              'L’accès est limité au périmètre de votre commune.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: CitizenDesignTokens.textSubtle,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}