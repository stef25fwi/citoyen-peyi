import 'dart:convert';

import 'package:http/http.dart' as http;

/// Une commune normalisee issue du referentiel officiel (geo.api.gouv.fr) :
/// nom, code INSEE et codes postaux. Sert de source unique pour rendre le
/// remplissage ville / CP / INSEE predictif et coherent dans toute l'app.
class CommuneSuggestion {
  const CommuneSuggestion({
    required this.nom,
    required this.code,
    required this.codesPostaux,
  });

  /// Nom officiel de la commune (ex. "Les Abymes").
  final String nom;

  /// Code INSEE (ex. "97101"). Peut contenir 2A/2B pour la Corse.
  final String code;

  /// Codes postaux rattaches a la commune.
  final List<String> codesPostaux;

  String get firstPostal => codesPostaux.isNotEmpty ? codesPostaux.first : '';

  String get displayLabel =>
      codesPostaux.isEmpty ? nom : '$nom (${codesPostaux.join(', ')})';

  static CommuneSuggestion? fromApi(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final nom = CommuneLookupService.normalizeCommuneName(raw['nom'] as String?);
    final code = CommuneLookupService.normalizeInsee(raw['code'] as String?);
    if (nom.isEmpty || code.isEmpty) return null;
    final codesPostaux = (raw['codesPostaux'] as List<dynamic>?)
            ?.map((c) => CommuneLookupService.normalizePostal('$c'))
            .where((c) => c.isNotEmpty)
            .toList() ??
        const <String>[];
    return CommuneSuggestion(nom: nom, code: code, codesPostaux: codesPostaux);
  }
}

/// Recherche et normalise les communes via le referentiel officiel
/// geo.api.gouv.fr. Centralise la logique autrefois dupliquee dans les
/// dialogues de creation (profil admin, agent de mobilisation).
class CommuneLookupService {
  CommuneLookupService({http.Client? client})
      : _client = client ?? http.Client();

  static final CommuneLookupService instance = CommuneLookupService();

  final http.Client _client;

  static const _fields = 'nom,code,codesPostaux,population';

  /// Nom de commune : trim + espaces multiples reduits.
  static String normalizeCommuneName(String? value) =>
      (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Code INSEE : majuscules, sans espaces (gere 2A/2B Corse).
  static String normalizeInsee(String? value) =>
      (value ?? '').trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  /// Code postal : chiffres uniquement, tronque a 5.
  static String normalizePostal(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length > 5 ? digits.substring(0, 5) : digits;
  }

  /// Recherche par nom (texte) ou par code postal (2 a 5 chiffres).
  /// Retourne une liste vide si la requete est trop courte ou en cas d'erreur.
  Future<List<CommuneSuggestion>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final isPostal = RegExp(r'^\d{2,5}$').hasMatch(q);
    final url = isPostal
        ? 'https://geo.api.gouv.fr/communes?codePostal=$q&fields=$_fields&limit=10'
        : 'https://geo.api.gouv.fr/communes?nom=${Uri.encodeComponent(q)}&fields=$_fields&boost=population&limit=10';

    final response =
        await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return const [];
    final data = jsonDecode(response.body);
    if (data is! List) return const [];
    return data
        .map(CommuneSuggestion.fromApi)
        .whereType<CommuneSuggestion>()
        .toList(growable: false);
  }
}
