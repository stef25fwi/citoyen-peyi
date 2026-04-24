import 'package:flutter/material.dart';

import '../services/admin_auth_service.dart';

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
        if (!mounted) {
          return;
        }

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
    if (accessKey.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await AdminAuthService.instance.signInWithAccessKey(accessKey);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isFallback
                ? 'Mode local actif. Acces administrateur ouvert sans echange backend.'
                : 'Connexion administrateur securisee etablie.',
          ),
        ),
      );

      Navigator.of(context).pushReplacementNamed('/admin');
    } on AdminAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion administrateur impossible.')),
      );
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
    final canSubmit = _accessKeyController.text.trim().isNotEmpty && !_isSubmitting;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Icon(Icons.settings_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Espace administrateur'),
          ],
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
                      child: Icon(
                        Icons.lock_rounded,
                        size: 34,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Connexion administrateur',
                      style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Entrez votre cle d\'acces administrateur pour recevoir un jeton de confiance emis par le backend.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF5A6573)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _accessKeyController,
                      obscureText: true,
                      enabled: !_isSubmitting,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cle administrateur',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                      onSubmitted: (_) {
                        if (canSubmit) {
                          _handleSubmit();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canSubmit ? _handleSubmit : null,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(_isSubmitting ? 'Connexion en cours...' : 'Acceder au tableau de bord'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'En mode configure, cette cle sera verifiee par le backend avant emission des claims admin.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF7A8796)),
                      textAlign: TextAlign.center,
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