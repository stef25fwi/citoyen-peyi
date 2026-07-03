import 'package:flutter/material.dart';

class VoteConfirmationPage extends StatelessWidget {
  const VoteConfirmationPage({
    this.pollTitle,
    this.communeName,
    super.key,
  });

  final String? pollTitle;
  final String? communeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 52, color: Color(0xFF2E7D32)),
                    const SizedBox(height: 16),
                    Text(
                      'Votre vote est enregistre anonymement.',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Votre identite n\'est pas liee a votre choix.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (pollTitle != null || communeName != null) ...[
                      const SizedBox(height: 20),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD7E0EA)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (pollTitle != null) Text('Consultation: $pollTitle', textAlign: TextAlign.center),
                              if (communeName != null) ...[
                                if (pollTitle != null) const SizedBox(height: 6),
                                Text('Commune: $communeName', textAlign: TextAlign.center),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/access', (_) => false),
                        child: const Text('Acceder a un autre code citoyen'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
                      child: const Text('Retour a l\'accueil'),
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