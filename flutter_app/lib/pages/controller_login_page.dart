import 'package:flutter/material.dart';

import '../services/controller_auth_service.dart';

class _ControllerLoginTheme {
  static const background = Color(0xFFF6F7F9);
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
      final result = await ControllerAuthService.instance
          .signInWithCode(_codeController.text);
      if (!mounted) {
        return;
      }

      final commune = result.session.commune?.name;
      final message = commune == null || commune.isEmpty
          ? 'Bienvenue, ${result.session.label ?? 'Agent de mobilisation citoyenne'}'
          : 'Bienvenue, ${result.session.label ?? 'Agent de mobilisation citoyenne'} · $commune';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pushReplacementNamed('/controleur');
    } on ControllerAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
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
            Icon(Icons.assignment_turned_in_rounded,
                color: _ControllerLoginTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('Espace agent de mobilisation citoyenne',
                style: TextStyle(fontSize: 14)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pushNamed('/'),
        ),
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
                              theme.colorScheme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.key_rounded,
                            size: 28, color: _ControllerLoginTheme.primary),
                      ),
                      const SizedBox(height: 12),
                      Text('Connexion agent de mobilisation citoyenne',
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 18, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(
                        'Entrez le code fourni par un administrateur pour acceder a l\'interface de verification des pieces.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: _ControllerLoginTheme.mutedForeground),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _codeController,
                        enabled: !_isSubmitting,
                        autofocus: true,
                        maxLength: 13,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Ex : A3F2B1C9',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: _ControllerLoginTheme.border),
                          ),
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
                                  offset: normalized.length),
                            );
                          }
                          setState(() {});
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: _LoginGradientButton(
                          onPressed: _isSubmitting ||
                                  _codeController.text.trim().isEmpty
                              ? null
                              : _submit,
                          isLoading: _isSubmitting,
                          label: _isSubmitting
                              ? 'Connexion en cours...'
                              : 'Acceder a mon profil',
                        ),
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
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
            else ...[
              Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? Colors.white
                      : _ControllerLoginTheme.mutedForeground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  color: enabled
                      ? Colors.white
                      : _ControllerLoginTheme.mutedForeground,
                  size: 18),
            ],
            if (isLoading) ...[
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ],
        ),
      ),
    );
  }
}
