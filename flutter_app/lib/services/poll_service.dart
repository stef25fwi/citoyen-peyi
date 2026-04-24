import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/poll_models.dart';
import 'browser_storage_service.dart';
import 'firestore_data_service.dart';

class PollService {
  PollService._();

  static const _pollStorageKey = 'polls_v1';
  static const _pollCollection = 'polls';
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

  List<PollModel> _readLocalPolls(List<dynamic> records) {
    if (records.isEmpty) {
      return _fallbackPolls;
    }

    final polls = records
        .whereType<Map<String, dynamic>>()
        .map(PollModel.fromJson)
        .toList();
    return polls.isEmpty ? _fallbackPolls : polls;
  }

  Future<List<PollModel>> _loadLocalPolls() async {
    final records = await BrowserStorageService.instance.readJsonList(_pollStorageKey);
    return _readLocalPolls(records);
  }

  Future<void> _writeLocalPolls(List<PollModel> polls) {
    return BrowserStorageService.instance.writeJsonList(
      _pollStorageKey,
      polls.map((item) => item.toJson()).toList(),
    );
  }

  String _derivePollStatus(String openDate, String closeDate) {
    final today = DateTime.now().toIso8601String().split('T').first;

    if (closeDate.isNotEmpty && closeDate.compareTo(today) < 0) {
      return 'closed';
    }

    if (openDate.isEmpty || openDate.compareTo(today) > 0) {
      return 'draft';
    }

    return 'active';
  }

  Future<List<PollModel>> loadPolls() async {
    final db = FirestoreDataService.instance;
    if (db == null) {
      return _loadLocalPolls();
    }

    try {
      final snapshot = await db.collection(_pollCollection).get();
      if (snapshot.docs.isEmpty) {
        return _loadLocalPolls();
      }

      final polls = snapshot.docs
          .map((item) => PollModel.fromJson(item.data()))
          .toList()
        ..sort((left, right) => right.openDate.compareTo(left.openDate));
      await _writeLocalPolls(polls);
      return polls;
    } catch (_) {
      return _loadLocalPolls();
    }
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

  Future<PollModel> createPoll({
    required String projectTitle,
    required String question,
    required List<String> options,
    required String openDate,
    required String closeDate,
    required int totalVoters,
  }) async {
    final now = DateTime.now().microsecondsSinceEpoch;
    final poll = PollModel(
      id: 'poll-$now',
      projectTitle: projectTitle.trim(),
      question: question.trim(),
      options: options
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map((entry) => PollOptionModel(
                id: 'opt-$now-${entry.key + 1}',
                label: entry.value,
                votes: 0,
              ))
          .toList(),
      openDate: openDate,
      closeDate: closeDate,
      status: _derivePollStatus(openDate, closeDate),
      totalVoters: totalVoters,
      totalVoted: 0,
    );

    final polls = await loadPolls();
    final nextPolls = [poll, ...polls];
    await _writeLocalPolls(nextPolls);

    final db = FirestoreDataService.instance;
    if (db != null) {
      await db.collection(_pollCollection).doc(poll.id).set(
        poll.toJson(),
        SetOptions(merge: true),
      );
    }

    return poll;
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

    await _writeLocalPolls(nextPolls);

    final db = FirestoreDataService.instance;
    if (db != null && updatedPoll != null) {
      await db.collection(_pollCollection).doc(updatedPoll!.id).set(
        updatedPoll!.toJson(),
        SetOptions(merge: true),
      );
    }

    return updatedPoll;
  }
}
