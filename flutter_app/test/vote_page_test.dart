import 'dart:async';

import 'package:citoyen_peyi_flutter/pages/vote_page.dart';
import 'package:citoyen_peyi_flutter/services/vote_access_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VotePage shows already voted state', (tester) async {
    final service = _FakeVoteAccessService(
      validationResult: VoteAccessValidationResult(
        accessToken: 'token',
        accessCodeId: 'code-1',
        communeId: 'commune-1',
        communeName: 'Fort-de-France',
        eligiblePolls: const [
          EligiblePollModel(
            pollId: 'poll-1',
            title: 'Budget participatif',
            status: 'open',
            hasVoted: true,
            question: 'Quelle priorite ?',
            options: [EligiblePollOption(id: 'opt-1', label: 'Option A')],
          ),
        ],
      ),
    );

    await tester.pumpWidget(_buildTestApp(service: service, pollId: 'poll-1'));
    await tester.pumpAndSettle();

    expect(find.text('Merci pour votre vote'), findsOneWidget);
    expect(find.textContaining('deja ete enregistre'), findsOneWidget);
  });

  testWidgets('VotePage prevents double submission while request is pending',
      (tester) async {
    final submitCompleter = Completer<VoteSubmitResult>();
    final service = _FakeVoteAccessService(
      validationResult: VoteAccessValidationResult(
        accessToken: 'token',
        accessCodeId: 'code-1',
        communeId: 'commune-1',
        communeName: 'Fort-de-France',
        eligiblePolls: const [
          EligiblePollModel(
            pollId: 'poll-1',
            title: 'Budget participatif',
            status: 'open',
            hasVoted: false,
            question: 'Quelle priorite ?',
            options: [
              EligiblePollOption(id: 'opt-1', label: 'Option A'),
              EligiblePollOption(id: 'opt-2', label: 'Option B'),
            ],
          ),
        ],
      ),
      onSubmit: ({required accessToken, required pollId, required optionId}) {
        return submitCompleter.future;
      },
    );

    await tester.pumpWidget(_buildTestApp(service: service, pollId: 'poll-1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Option A'));
    await tester.pump();

    final submitButton = find.text('Confirmer mon vote');
    await tester.tap(submitButton);
    await tester.pump();

    expect(service.submitCalls, 1);
    expect(find.text('Enregistrement...'), findsOneWidget);

    await tester.tap(find.text('Enregistrement...'));
    await tester.pump();

    expect(service.submitCalls, 1);

    submitCompleter.complete(
        const VoteSubmitResult(receiptId: 'receipt-1', message: 'OK'));
    await tester.pumpAndSettle();
  });
}

Widget _buildTestApp(
    {required VoteAccessService service, required String pollId}) {
  return MaterialApp(
    routes: {
      '/access': (_) => const Scaffold(body: Text('Access')),
      '/confirmation': (_) => const Scaffold(body: Text('Confirmation')),
    },
    home: VotePage(
      token: 'AB12CD34',
      pollId: pollId,
      voteAccessService: service,
    ),
  );
}

class _FakeVoteAccessService extends VoteAccessService {
  _FakeVoteAccessService({
    this.validationResult,
    this.onSubmit,
  }) : super();

  final VoteAccessValidationResult? validationResult;
  final Future<VoteSubmitResult> Function({
    required String accessToken,
    required String pollId,
    required String optionId,
  })? onSubmit;

  int submitCalls = 0;

  @override
  Future<VoteAccessValidationResult> validateCode(String rawCode,
      {String? pollId}) async {
    return validationResult!;
  }

  @override
  Future<VoteSubmitResult> submitVote({
    required String accessToken,
    required String pollId,
    required String optionId,
  }) {
    submitCalls += 1;
    if (onSubmit != null) {
      return onSubmit!(
          accessToken: accessToken, pollId: pollId, optionId: optionId);
    }
    return Future.value(
        const VoteSubmitResult(receiptId: 'receipt-1', message: 'OK'));
  }
}
