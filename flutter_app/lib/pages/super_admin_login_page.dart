import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/debug_log_service.dart';
import '../services/super_admin_service.dart';
import '../theme/citizen_design_tokens.dart';
import '../widgets/debug_log_viewer.dart';

class SuperAdminLoginPage extends StatefulWidget {
  const SuperAdminLoginPage({super.key});

  @override
  State<SuperAdminLoginPage> createState() => _SuperAdminLoginPageState();
}

class _SuperAdminLoginPageState extends State<SuperAdminLoginPage> {
  final _keyController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final key = _keyController.text.trim();
    if (key.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await SuperAdminService.instance.signIn(key);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/super');
    } on SuperAdminAuthException catch (error) {
      DebugLogService.instance.log(
        '[SuperAdminLogin]',
        'SuperAdminAuthException: ${error.message}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error, stackTrace) {
      DebugLogService.instance.log(
        '[SuperAdminLogin]',
        'Erreur inattendue: $error\n$stackTrace',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode
                ? 'Connexion impossible. Consultez le journal Debug.'
                : 'Connexion super administrateur impossible.',
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
    final canSubmit = _keyController.text.trim().isNotEmpty && !_isSubmitting;

    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/'),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              color: CitizenDesignTokens.superAdminAccent,
              size: 22,
            ),
            SizedBox(width: CitizenDesignTokens.space8),
            Flexible(child: Text('Espace Super Administrateur')),
          ],
        ),
        actions: kDebugMode ? const [DebugLogButton()] : null,
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
                        decoration: CitizenDesignTokens.elevatedCardDecoration,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: CitizenDesignTokens.superAdminSoft,
                                borderRadius: BorderRadius.circular(
                                  CitizenDesignTokens.radiusButton,
                                ),
                                border: Border.all(
                                  color: CitizenDesignTokens.superAdminAccent
                                      .withValues(alpha: 0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 30,
                                color: CitizenDesignTokens.superAdminAccent,
                              ),
                            ),
                            const SizedBox(height: CitizenDesignTokens.space16),
                            Text(
                              'Connexion Super Admin',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: CitizenDesignTokens.space8),
                            Text(
                              'Pilotez les communes, les administrateurs, les sauvegardes et la supervision globale de la plateforme.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: CitizenDesignTokens.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: CitizenDesignTokens.space24),
                            TextField(
                              controller: _keyController,
                              obscureText: _obscure,
                              enabled: !_isSubmitting,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                letterSpacing: 1,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Clé super administrateur',
                                prefixIcon: const Icon(
                                  Icons.key_rounded,
                                  color: CitizenDesignTokens.superAdminAccent,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    CitizenDesignTokens.radiusField,
                                  ),
                                  borderSide: const BorderSide(
                                    color: CitizenDesignTokens.superAdminAccent,
                                    width: 1.8,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscure
                                      ? 'Afficher la clé'
                                      : 'Masquer la clé',
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) {
                                if (canSubmit) _handleSubmit();
                              },
                            ),
                            const SizedBox(height: CitizenDesignTokens.space16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      CitizenDesignTokens.superAdminAccent,
                                ),
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
                                      : 'Accéder au panneau Super Admin',
                                ),
                              ),
                            ),
                            const SizedBox(height: CitizenDesignTokens.space12),
                            Text(
                              'La clé est vérifiée par le serveur et n’est jamais intégrée au code de l’application.',
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
