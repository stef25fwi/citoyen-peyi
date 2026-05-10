import 'dart:convert';

import 'package:citoyen_peyi_flutter/services/vote_access_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('VoteAccessService.parseCodeOrQrUrl', () {
    final service = VoteAccessService();

    test('extracts raw code', () {
      expect(service.parseCodeOrQrUrl(' ab12cd34 '), 'AB12CD34');
    });

    test('extracts code from query parameter', () {
      expect(
        service.parseCodeOrQrUrl('https://citoyen.peyi/access?code=ab12cd34'),
        'AB12CD34',
      );
    });

    test('extracts token from vote route', () {
      expect(
        service.parseCodeOrQrUrl('https://citoyen.peyi/vote/ab12cd34'),
        'AB12CD34',
      );
    });
  });

  group('VoteAccessService.validateCode', () {
    test('returns parsed payload on success', () async {
      final service = VoteAccessService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/vote-access/validate');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['code'], 'AB12CD34');

          return http.Response(
            jsonEncode({
              'ok': true,
              'accessToken': 'signed-token',
              'accessCodeId': 'AB12CD34',
              'communeId': 'commune-1',
              'communeName': 'Fort-de-France',
              'eligiblePolls': [
                {
                  'pollId': 'poll-1',
                  'title': 'Budget participatif',
                  'question': 'Quelle priorite ?',
                  'status': 'open',
                  'hasVoted': false,
                  'options': [
                    {'id': 'opt-1', 'label': 'Option A'},
                  ],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await service.validateCode('ab12cd34');

      expect(result.accessToken, 'signed-token');
      expect(result.communeName, 'Fort-de-France');
      expect(result.eligiblePolls, hasLength(1));
      expect(result.eligiblePolls.first.options.single.label, 'Option A');
    });

    test('throws VoteAccessException on API error', () async {
      final service = VoteAccessService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'ok': false,
              'errorCode': 'INVALID_CODE',
              'message': 'Code inconnu.',
            }),
            404,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      expect(
        () => service.validateCode('invalid'),
        throwsA(
          isA<VoteAccessException>()
              .having((error) => error.errorCode, 'errorCode', 'INVALID_CODE')
              .having((error) => error.message, 'message', 'Code inconnu.'),
        ),
      );
    });
  });
}