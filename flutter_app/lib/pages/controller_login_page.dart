import 'package:flutter/material.dart';

import '../services/controller_auth_service.dart';

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
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Espace controleur'),
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
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.key_rounded, size: 34, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 18),
                    Text('Connexion controleur', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      'Entrez le code fourni par un administrateur pour acceder a l\'interface de controle des pieces.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF5A6573)),
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
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
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
                      child: FilledButton.icon(
                        onPressed: _isSubmitting || _codeController.text.trim().isEmpty ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(_isSubmitting ? 'Connexion en cours...' : 'Acceder a mon profil'),
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
