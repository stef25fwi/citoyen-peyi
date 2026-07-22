import 'package:citoyen_peyi_flutter/models/poll_models.dart';
import 'package:citoyen_peyi_flutter/pages/home_page.dart';
import 'package:citoyen_peyi_flutter/pages/citizen/citizen_home_page.dart';
import 'package:citoyen_peyi_flutter/services/citizen_public_access_service.dart';
import 'package:citoyen_peyi_flutter/services/vote_access_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'accueil public → code → accueil connecté → vote → confirmation → déconnexion',
    (tester) async {
      tester.view.physicalSize = const Size(430, 980);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await CitizenPublicAccessService.instance.clearSession();

      final fakeVoteService = _FakeVoteAccessService();
      final session = _buildSession();

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const HomePage(),
                );
              case '/access':
              case '/access-citizen':
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => _FakeCitizenAccessPage(session: session),
                );
              case '/citizen/home':
              case '/citizen/welcome':
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => CitizenHomePage(
                    initialSession:
                        CitizenPublicAccessService.instance.currentSession,
                    voteAccessService: fakeVoteService,
                  ),
                );
              default:
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const Scaffold(
                    body: Center(child: Text('Route de test introuvable')),
                  ),
                );
            }
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Je participe'), findsOneWidget);
      await tester.ensureVisible(find.text('Je participe'));
      await tester.tap(find.text('Je participe'));
      await tester.pumpAndSettle();

      expect(find.text('Saisissez votre code citoyen'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'CP-2026-TEST');
      await tester.tap(find.text('Valider mon code citoyen'));
      await tester.pumpAndSettle();

      expect(find.text('Bonjour !'), findsOneWidget);
      expect(find.byKey(const ValueKey('citizenHomeParticipateButton')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('citizenHomeParticipateButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consultation de test'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('consultationCard_poll-1')));
      await tester.pumpAndSettle();

      expect(find.text('Quel projet préférez-vous ?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pollOption_Option A')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('citizenVoteContinueButton')));
      await tester.pumpAndSettle();

      expect(find.text('Votre réponse a bien été enregistrée.'), findsOneWidget);
      expect(
        await CitizenPublicAccessService.instance.hasVoted(
          accessCode: session.accessCode,
          pollId: 'poll-1',
        ),
        isTrue,
      );

      await tester.tap(
        find.byKey(const ValueKey('voteConfirmationHomeButton')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bonjour !'), findsOneWidget);
      expect(find.text('0'), findsWidgets);

      await tester.tap(find.byTooltip('Mon profil'));
      await tester.pumpAndSettle();
      expect(find.text('Mon profil'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('citizenLogoutButton')),
      );
      await tester.tap(find.byKey(const ValueKey('citizenLogoutButton')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('confirmCitizenLogoutButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saisissez votre code citoyen'), findsOneWidget);
      expect(CitizenPublicAccessService.instance.currentSession, isNull);
    },
  );
}

CitizenPublicAccessSession _buildSession() {
  return CitizenPublicAccessSession(
    accessCode: 'CP-2026-TEST',
    communeId: '97101',
    communeName: 'Commune test',
    openPolls: const [
      PollModel(
        id: 'poll-1',
        projectTitle: 'Consultation de test',
        description: 'Une consultation utilisée pour le parcours complet.',
        question: 'Quel projet préférez-vous ?',
        options: [
          PollOptionModel(id: 'a', label: 'Option A', votes: 0),
          PollOptionModel(id: 'b', label: 'Option B', votes: 0),
        ],
        photoUrls: [],
        openDate: '2026-07-01',
        closeDate: '2026-08-01',
        status: 'active',
        totalVoters: 0,
        totalVoted: 0,
      ),
    ],
    votedPollIds: {},
  );
}

class _FakeCitizenAccessPage extends StatefulWidget {
  const _FakeCitizenAccessPage({required this.session});

  final CitizenPublicAccessSession session;

  @override
  State<_FakeCitizenAccessPage> createState() => _FakeCitizenAccessPageState();
}

class _FakeCitizenAccessPageState extends State<_FakeCitizenAccessPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    if (_controller.text.trim().isEmpty) return;
    await CitizenPublicAccessService.instance.saveSession(widget.session);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/citizen/home',
      (route) => false,
      arguments: {'session': widget.session},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Saisissez votre code citoyen'),
              const SizedBox(height: 16),
              TextField(controller: _controller),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _validate,
                child: const Text('Valider mon code citoyen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FakeVoteAccessService extends VoteAccessService {
  @override
  Future<VoteAccessValidationResult> validateCode(
    String rawCode, {
    String? pollId,
  }) async {
    return const VoteAccessValidationResult(
      accessToken: 'token-test',
      accessCodeId: 'code-test',
      communeId: '97101',
      communeName: 'Commune test',
      eligiblePolls: [
        EligiblePollModel(
          pollId: 'poll-1',
          title: 'Consultation de test',
          status: 'open',
          hasVoted: false,
          accessToken: 'poll-token-test',
          questions: [
            EligiblePollQuestion(
              id: 'question-1',
              title: 'Quel projet préférez-vous ?',
              options: [
                EligiblePollOption(id: 'a', label: 'Option A'),
                EligiblePollOption(id: 'b', label: 'Option B'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<VoteSubmitResult> submitVote({
    required String accessToken,
    required String pollId,
    String optionId = '',
    List<PollAnswer> answers = const [],
  }) async {
    return const VoteSubmitResult(
      receiptId: 'receipt-test',
      message: 'Vote enregistré',
    );
  }
}
