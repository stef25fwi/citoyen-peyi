import 'package:flutter/material.dart';

import '../services/controller_auth_service.dart';

class _ControllerLoginTheme {
  static const background = Color(0xFFF6F7F9);
  static const foreground = Color(0xFF0F172A);
  static const mutedForeground = Color(0xFF64748B);
  static const border = Color(0xFFE5E7EB);
  static const primary = Color(0xFF0D73F2);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D73F2), Color(0xFF4F70F5)],
  );
}

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
    if (_isSubmitting || _codeController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ControllerAuthService.instance.signInWithCode(_codeController.text);
      if (!mounted) {
        return;
      }

      final commune = result.session.commune?.name;
      final message = commune == null || commune.isEmpty
          ? 'Bienvenue, ${result.session.label ?? 'Controleur'}'
          : 'Bienvenue, ${result.session.label ?? 'Controleur'} · $commune';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pushReplacementNamed('/admin/inscriptions');
    } on ControllerAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _ControllerLoginTheme.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_turned_in_rounded, color: _ControllerLoginTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('Espace controleur'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.key_rounded, size: 34, color: _ControllerLoginTheme.primary),
                    ),
                    const SizedBox(height: 18),
                    Text('Connexion controleur', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      'Entrez le code fourni par un administrateur pour acceder a l\'interface de controle des pieces.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: _ControllerLoginTheme.mutedForeground),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      enabled: !_isSubmitting,
                      autofocus: true,
                      maxLength: 20,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, letterSpacing: 1, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Ex : CTRL-A1B2C3D4',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: _ControllerLoginTheme.border),
                        ),
                      ),
                      onChanged: (value) {
                        final upper = value.toUpperCase();
                        if (upper != value) {
                          _codeController.value = _codeController.value.copyWith(
                            text: upper,
                            selection: TextSelection.collapsed(offset: upper.length),
                          );
                        }
                        setState(() {});
                      },
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _LoginGradientButton(
                        onPressed: _isSubmitting || _codeController.text.trim().isEmpty ? null : _submit,
                        isLoading: _isSubmitting,
                        label: _isSubmitting ? 'Connexion en cours...' : 'Acceder a mon profil',
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _codeController.text = 'ADMIN2026';
                        setState(() {});
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 8),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                                children: [
                                  TextSpan(text: 'Mode demo · code : '),
                                  TextSpan(
                                    text: 'ADMIN2026',
                                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
                                  ),
                                  TextSpan(text: '  (appuyez pour remplir)'),
                                ],
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
        ),
      ),
    );
  }
}

class _LoginGradientButton extends StatelessWidget {
  const _LoginGradientButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled ? _ControllerLoginTheme.gradient : null,
          color: enabled ? null : const Color(0xFFF1F3F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else ...[
              Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : _ControllerLoginTheme.mutedForeground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: enabled ? Colors.white : _ControllerLoginTheme.mutedForeground, size: 18),
            ],
            if (isLoading) ...[
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ],
        ),
      ),
    );
  }
}
