import 'package:flutter/material.dart';

import '../services/admin_auth_service.dart';
import '../theme/citizen_design_tokens.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({
    this.blockedMessage,
    super.key,
  });

  final String? blockedMessage;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _accessKeyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.blockedMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.blockedMessage!)),
        );
      });
    }
  }

  @override
  void dispose() {
    _accessKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final accessKey = _accessKeyController.text.trim();
    if (accessKey.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await AdminAuthService.instance.signInWithAccessKey(accessKey);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connexion administrateur communal sécurisée établie.',
          ),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/admin');
    } on AdminAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connexion administrateur communal impossible : ${error.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit =
        _accessKeyController.text.trim().isNotEmpty && !_isSubmitting;

    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            Icon(
              Icons.settings_rounded,
              color: CitizenDesignTokens.primaryBlue,
              size: 22,
            ),
            SizedBox(width: CitizenDesignTokens.space8),
            Flexible(child: Text('Espace administrateur communal')),
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
                                Icons.lock_rounded,
                                size: 29,
                                color: CitizenDesignTokens.primaryBlue,
                              ),
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space16),
                            Text(
                              'Connexion administrateur communal',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space8),
                            Text(
                              'Accédez à la gestion des consultations, des agents et des résultats de votre commune.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: CitizenDesignTokens.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space24),
                            TextField(
                              controller: _accessKeyController,
                              obscureText: true,
                              enabled: !_isSubmitting,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                letterSpacing: 1,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Clé administrateur communal',
                                prefixIcon: Icon(Icons.key_rounded),
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) {
                                if (canSubmit) _handleSubmit();
                              },
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: canSubmit ? _handleSubmit : null,
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
                                      : 'Accéder au tableau de bord',
                                ),
                              ),
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space12),
                            Text(
                              'Votre clé est vérifiée de manière sécurisée par le serveur.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: CitizenDesignTokens.textSubtle,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                                height: CitizenDesignTokens.space4),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .pushNamed('/super/login'),
                              icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 18,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    CitizenDesignTokens.superAdminAccent,
                              ),
                              label:
                                  const Text('Espace Super Administrateur'),
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