import 'package:citoyen_peyi_flutter/pages/citizen/citizen_poll_question_page.dart';
import 'package:citoyen_peyi_flutter/services/vote_access_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('share button copies a real consultation link to the clipboard',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final service = _FakeVoteAccessService(
      validationResult: VoteAccessValidationResult(
        accessToken: 'token',
        accessCodeId: 'code-1',
        communeId: 'commune-1',
        communeName: 'Fort-de-France',
        eligiblePolls: const [
          EligiblePollModel(
            pollId: 'poll-1',
            title: 'Aménagement des espaces publics',
            status: 'active',
            hasVoted: false,
            accessToken: 'poll-token',
            questions: [
              EligiblePollQuestion(
                id: 'q1',
                title: 'Priorités ?',
                options: [EligiblePollOption(id: 'o1', label: 'Parcs')],
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CitizenPollQuestionPage(
          title: 'Aménagement des espaces publics',
          pollId: 'poll-1',
          accessCode: 'AB12CD34',
          voteAccessService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Partager'));
    await tester.pump();

    expect(copiedText, isNotNull);
    expect(copiedText, contains('Aménagement des espaces publics'));
    expect(copiedText, contains('poll=poll-1'));
    expect(find.text('Lien de la consultation copié.'), findsOneWidget);
  });
  testWidgets('redirects to /access when there is no citizen access session',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/access': (_) => const Scaffold(body: Text('Access')),
        },
        home: const CitizenPollQuestionPage(title: 'Consultation'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Access'), findsOneWidget);
  });

  testWidgets(
      'steps through a multi-question survey and submits real answers',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _FakeVoteAccessService(
      validationResult: VoteAccessValidationResult(
        accessToken: 'token',
        accessCodeId: 'code-1',
        communeId: 'commune-1',
        communeName: 'Fort-de-France',
        eligiblePolls: const [
          EligiblePollModel(
            pollId: 'poll-1',
            title: 'Aménagement des espaces publics',
            status: 'active',
            hasVoted: false,
            accessToken: 'poll-token',
            questions: [
              EligiblePollQuestion(
                id: 'q1',
                title: 'Priorités ?',
                multiple: true,
                options: [
                  EligiblePollOption(id: 'o1', label: 'Parcs'),
                  EligiblePollOption(id: 'o2', label: 'Éclairage'),
                ],
              ),
              EligiblePollQuestion(
                id: 'q2',
                title: 'Autre priorité ?',
                multiple: false,
                options: [
                  EligiblePollOption(id: 'o3', label: 'Sécurité'),
                  EligiblePollOption(id: 'o4', label: 'Transport'),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CitizenPollQuestionPage(
          title: 'Aménagement des espaces publics',
          pollId: 'poll-1',
          accessCode: 'AB12CD34',
          voteAccessService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Étape 1 sur 2'), findsOneWidget);
    expect(find.text('1. Priorités ?'), findsOneWidget);

    await tester.tap(find.text('Parcs'));
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.text('Étape 2 sur 2'), findsOneWidget);
    expect(find.text('2. Autre priorité ?'), findsOneWidget);

    await tester.tap(find.text('Sécurité'));
    await tester.pump();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();

    expect(service.submitCalls, 1);
    expect(
      service.lastAnswers!.map((answer) => answer.toJson()).toList(),
      [
        {
          'questionId': 'q1',
          'optionIds': ['o1']
        },
        {
          'questionId': 'q2',
          'optionIds': ['o3']
        },
      ],
    );
    expect(find.text('Votre réponse a bien été enregistrée.'), findsOneWidget);
  });
}

class _FakeVoteAccessService extends VoteAccessService {
  _FakeVoteAccessService({required this.validationResult}) : super();

  final VoteAccessValidationResult validationResult;

  int submitCalls = 0;
  List<PollAnswer>? lastAnswers;

  @override
  Future<VoteAccessValidationResult> validateCode(String rawCode,
      {String? pollId}) async {
    return validationResult;
  }

  @override
  Future<VoteSubmitResult> submitVote({
    required String accessToken,
    required String pollId,
    String optionId = '',
    List<PollAnswer> answers = const [],
  }) async {
    submitCalls += 1;
    lastAnswers = answers;
    return const VoteSubmitResult(receiptId: 'receipt-1', message: 'OK');
  }
}
