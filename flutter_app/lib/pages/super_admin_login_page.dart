import 'package:flutter/material.dart';

import '../services/debug_log_service.dart';
import '../services/super_admin_service.dart';
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
    } on SuperAdminAuthException catch (e) {
      DebugLogService.instance
          .log('[SuperAdminLogin]', 'SuperAdminAuthException: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (error, stackTrace) {
      // Ne plus avaler l'erreur reelle : elle est capturee dans le journal de
      // diagnostic (bouton Debug) pour identifier la cause exacte.
      DebugLogService.instance.log('[SuperAdminLogin]',
          'Erreur inattendue: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connexion super administrateur impossible. '
                'Ouvrez « Debug » pour voir le detail.')),
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
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/'),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded,
                color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            const Flexible(child: Text('Espace Super Administrateur')),
          ],
        ),
        actions: const [DebugLogButton()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6B21A8).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 28,
                          color: Color(0xFF6B21A8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Connexion Super Admin',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ce profil peut creer des comptes administrateurs rattaches a une commune et generer leurs cles de connexion.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFF5A6573)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _keyController,
                        obscureText: _obscure,
                        enabled: !_isSubmitting,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cle super administrateur',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFD7E0EA)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFD7E0EA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFF6B21A8), width: 1.6),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) {
                          if (canSubmit) _handleSubmit();
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6B21A8),
                          ),
                          onPressed: canSubmit ? _handleSubmit : null,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          label: Text(_isSubmitting
                              ? 'Connexion...'
                              : 'Acceder au panneau super admin'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La cle super administrateur est verifiee par le backend et n\'est jamais compilee dans Flutter.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFF7A8796)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
