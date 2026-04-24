import '../models/poll_models.dart';
import 'browser_storage_service.dart';

class PollService {
  PollService._();

  static const _pollStorageKey = 'polls_v1';
  static final PollService instance = PollService._();

  static const List<PollModel> _fallbackPolls = [
    PollModel(
      id: 'poll-1',
      projectTitle: 'Reamenagement de la Place Centrale',
      question: 'Quelle option preferez-vous pour le reamenagement de la Place Centrale ?',
      options: [
        PollOptionModel(id: 'opt-1', label: 'Espace vert avec aires de jeux', votes: 47),
        PollOptionModel(id: 'opt-2', label: 'Marche couvert et terrasses', votes: 32),
        PollOptionModel(id: 'opt-3', label: 'Parking souterrain et esplanade pietonne', votes: 28),
        PollOptionModel(id: 'opt-4', label: 'Zone mixte commerces et espaces verts', votes: 53),
      ],
      openDate: '2026-03-15',
      closeDate: '2026-04-15',
      status: 'active',
      totalVoters: 200,
      totalVoted: 160,
    ),
  ];

  Future<List<PollModel>> loadPolls() async {
    final records = await BrowserStorageService.instance.readJsonList(_pollStorageKey);
    if (records.isEmpty) {
      return _fallbackPolls;
    }

    final polls = records.map(PollModel.fromJson).toList();
    return polls.isEmpty ? _fallbackPolls : polls;
  }

  Future<PollModel?> loadPollById(String pollId) async {
    final polls = await loadPolls();
    for (final poll in polls) {
      if (poll.id == pollId) {
        return poll;
      }
    }
    return null;
  }

  Future<PollModel?> recordVote(String pollId, String optionId) async {
    final polls = await loadPolls();
    PollModel? updatedPoll;

    final nextPolls = polls.map((poll) {
      if (poll.id != pollId) {
        return poll;
      }

      updatedPoll = poll.copyWith(
        options: poll.options.map((option) {
          if (option.id != optionId) {
            return option;
          }

          return option.copyWith(votes: option.votes + 1);
        }).toList(),
        totalVoted: poll.totalVoted + 1,
      );

      return updatedPoll!;
    }).toList();

    await BrowserStorageService.instance.writeJsonList(
      _pollStorageKey,
      nextPolls.map((item) => item.toJson()).toList(),
    );

    return updatedPoll;
  }
}
