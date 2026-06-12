import 'package:flutter/foundation.dart';

/// Construit les liens profonds encodes dans les QR codes.
///
/// Un QR scanne par l'appareil photo natif ouvre une URL : il doit donc
/// contenir un lien complet (pas seulement le code brut) qui ramene
/// l'utilisateur sur la page de connexion correspondant a son profil, avec
/// le champ code prerempli.
///
/// L'app web utilise la strategie d'URL par hash (pas de usePathUrlStrategy) :
/// les routes profondes prennent la forme `${origin}/#/chemin?query`.
class DeepLinks {
  const DeepLinks._();

  /// Domaine de production utilise comme repli (ex. QR genere depuis le mobile).
  static const String productionOrigin = 'https://citoyen-peyi.web.app';

  static String _origin() {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      // Sur web l'agent et le citoyen partagent le meme domaine : on reprend
      // l'origine courante (production ou dev local) pour rester coherent.
      if (origin.isNotEmpty && origin != 'null') {
        return origin;
      }
    }
    return productionOrigin;
  }

  /// Lien d'acces citoyen avec le code prerempli, vers la page `/access`.
  static String citizenAccess(String accessCode) {
    final code = Uri.encodeQueryComponent(accessCode.trim());
    return '${_origin()}/#/access?code=$code';
  }
}
