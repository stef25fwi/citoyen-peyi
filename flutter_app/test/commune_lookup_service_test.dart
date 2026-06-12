import 'package:citoyen_peyi_flutter/services/commune_lookup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommuneLookupService normalisation', () {
    test('normalizeCommuneName trims and collapses whitespace', () {
      expect(CommuneLookupService.normalizeCommuneName('  Les   Abymes '),
          'Les Abymes');
      expect(CommuneLookupService.normalizeCommuneName(null), '');
    });

    test('normalizeInsee uppercases and strips spaces (handles 2A/2B)', () {
      expect(CommuneLookupService.normalizeInsee(' 97101 '), '97101');
      expect(CommuneLookupService.normalizeInsee('2a004'), '2A004');
      expect(CommuneLookupService.normalizeInsee(null), '');
    });

    test('normalizePostal keeps digits only, max 5', () {
      expect(CommuneLookupService.normalizePostal('97 122'), '97122');
      expect(CommuneLookupService.normalizePostal('971225'), '97122');
      expect(CommuneLookupService.normalizePostal('abc'), '');
    });

    test('CommuneSuggestion.fromApi normalises every field', () {
      final suggestion = CommuneSuggestion.fromApi({
        'nom': '  Les  Abymes ',
        'code': '97101',
        'codesPostaux': ['97139', '971 42'],
      });
      expect(suggestion, isNotNull);
      expect(suggestion!.nom, 'Les Abymes');
      expect(suggestion.code, '97101');
      expect(suggestion.codesPostaux, ['97139', '97142']);
      expect(suggestion.firstPostal, '97139');
      expect(suggestion.displayLabel, 'Les Abymes (97139, 97142)');
    });

    test('CommuneSuggestion.fromApi rejects entries without name or code', () {
      expect(CommuneSuggestion.fromApi({'nom': '', 'code': '97101'}), isNull);
      expect(CommuneSuggestion.fromApi({'nom': 'X', 'code': ''}), isNull);
      expect(CommuneSuggestion.fromApi('not-a-map'), isNull);
    });
  });
}
