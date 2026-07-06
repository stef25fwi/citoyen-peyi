import 'package:flutter/material.dart';

import '../pages/access_citizen_page.dart';

/// Bandeau invitant un citoyen non connecte a rejoindre son espace avec un
/// bouton « Je participe » qui ouvre la page d'acces citoyen.
class CitizenConnectInvite extends StatelessWidget {
  const CitizenConnectInvite({
    super.key,
    this.message =
        'Connectez-vous a votre compte pour participer aux consultations de votre commune.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A8FE8), Color(0xFF0756B8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0756B8).withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_open_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            'Rejoignez votre espace citoyen',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD83D),
                foregroundColor: const Color(0xFF0756B8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: () => Navigator.of(context)
                  .pushNamed(AccessCitizenPage.routeName),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Je participe'),
            ),
          ),
        ],
      ),
    );
  }
}
