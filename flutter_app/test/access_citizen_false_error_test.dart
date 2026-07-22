import 'package:citoyen_peyi_flutter/pages/access_citizen_page.dart';
import 'package:citoyen_peyi_flutter/services/citizen_public_access_service.dart';
import 'package:citoyen_peyi_flutter/services/vote_access_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'une panne de persistance après validation ne produit pas un faux message d’erreur',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AccessCitizenPage.legalTermsAcceptedKey: true,
      });
      await CitizenPublicAccessService.instance.clearSession();

      var persistenceAttempted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AccessCitizenPage(
            initialCode: 'CP-2026-TEST',
            voteAccessService: _SuccessfulVoteAccessService(),
            persistSession: (session) async {
              persistenceAttempted = true;
              throw StateError('stockage local indisponible');
            },
          ),
          routes: {
            '/citizen/welcome': (_) => const Scaffold(
                  body: Center(child: Text('ESPACE CITOYEN OUVERT')),
                ),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Valider mon code citoyen'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('ESPACE CITOYEN OUVERT'), findsOneWidget);
      expect(find.textContaining('Validation indisponible'), findsNothing);
      expect(find.textContaining('Validation sécurisée indisponible'), findsNothing);
      expect(persistenceAttempted, isTrue);
      expect(CitizenPublicAccessService.instance.currentSession, isNotNull);
      expect(
        CitizenPublicAccessService.instance.currentSession?.accessCode,
        'CP-2026-TEST',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _SuccessfulVoteAccessService extends VoteAccessService {
  @override
  Future<VoteAccessValidationResult> validateCode(
    String rawCode, {
    String? pollId,
  }) async {
    return const VoteAccessValidationResult(
      accessToken: 'token-test',
      accessCodeId: 'access-code-test',
      communeId: '97101',
      communeName: 'Commune test',
      eligiblePolls: [],
    );
  }
}
