import 'package:flutter/material.dart';

import '../../services/citizen_public_access_service.dart';
import 'citizen_home_page.dart';

/// Compatibilité avec les anciens liens `/citizen/welcome`.
///
/// L'onboarding ne doit jamais remplacer l'onglet Accueil après connexion.
/// Toute navigation historique vers cette page ouvre donc directement le
/// tableau de bord citoyen connecté.
class CitizenWelcomePage extends StatelessWidget {
  const CitizenWelcomePage({
    super.key,
    this.initialSession,
  });

  final CitizenPublicAccessSession? initialSession;

  @override
  Widget build(BuildContext context) {
    return CitizenHomePage(initialSession: initialSession);
  }
}
