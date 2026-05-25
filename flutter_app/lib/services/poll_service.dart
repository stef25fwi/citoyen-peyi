import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/poll_models.dart';
import 'auth_session_store.dart';
import 'browser_storage_service.dart';
import 'firestore_data_service.dart';

class PollService {
  PollService._();

  static const _pollStorageKey = 'polls_v1';
  static const _pollCollection = 'polls';
  static final PollService instance = PollService._();

  List<PollModel> _readLocalPolls(List<dynamic> records) {
    return records
        .whereType<Map<String, dynamic>>()
        .map(PollModel.fromJson)
        .toList();
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
    final session = AuthSessionStore.instance.currentSession;
    final communeScope = (session?.isCommuneAdmin == true || session?.isController == true)
        ? (session?.commune?.code ?? session?.commune?.name ?? '')
        : '';

    final db = FirestoreDataService.instance;
    if (db == null) {
      final polls = await _loadLocalPolls();
      return _filterByCommuneScope(polls, communeScope);
    }

    try {
      final snapshot = await db.collection(_pollCollection).get();
      if (snapshot.docs.isEmpty) {
        final polls = await _loadLocalPolls();
        return _filterByCommuneScope(polls, communeScope);
      }

      final polls = snapshot.docs
          .map((item) => PollModel.fromJson(item.data()))
          .toList()
        ..sort((left, right) => right.openDate.compareTo(left.openDate));
      await _writeLocalPolls(polls);
      return _filterByCommuneScope(polls, communeScope);
    } catch (_) {
      final polls = await _loadLocalPolls();
      return _filterByCommuneScope(polls, communeScope);
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
    String description = '',
    required String question,
    required List<String> options,
    String targetPopulation = '',
    required String openDate,
    required String closeDate,
    required int totalVoters,
  }) async {
    final now = DateTime.now().microsecondsSinceEpoch;
    final nowIso = DateTime.now().toIso8601String();
    final session = AuthSessionStore.instance.currentSession;
    final poll = PollModel(
      id: 'poll-$now',
      projectTitle: projectTitle.trim(),
      description: description.trim(),
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
      targetPopulation: targetPopulation.trim(),
      communeId: session?.commune?.code ?? '',
      communeName: session?.commune?.name ?? '',
      openDate: openDate,
      closeDate: closeDate,
      status: _derivePollStatus(openDate, closeDate),
      createdBy: session?.label ?? session?.id ?? 'commune_admin',
      createdAt: nowIso,
      updatedAt: nowIso,
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

  Future<PollModel?> updatePoll({
    required String pollId,
    required String projectTitle,
    String description = '',
    required String question,
    required List<String> options,
    String targetPopulation = '',
    required String openDate,
    required String closeDate,
    required int totalVoters,
  }) async {
    final polls = await loadPolls();
    final existing = polls.where((poll) => poll.id == pollId).firstOrNull;
    if (existing == null) {
      return null;
    }

    final trimmedOptions = options.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    final canEditOptions = existing.totalVoted == 0;
    final updatedOptions = canEditOptions
        ? trimmedOptions.asMap().entries.map((entry) {
            final previous = entry.key < existing.options.length ? existing.options[entry.key] : null;
            return PollOptionModel(
              id: previous?.id ?? 'opt-${existing.id}-${entry.key + 1}',
              label: entry.value,
              votes: previous?.votes ?? 0,
            );
          }).toList()
        : existing.options;

    final updated = existing.copyWith(
      projectTitle: projectTitle.trim(),
      description: description.trim(),
      question: question.trim(),
      options: updatedOptions,
      targetPopulation: targetPopulation.trim(),
      openDate: openDate,
      closeDate: closeDate,
      status: existing.status == 'archived' ? 'archived' : _derivePollStatus(openDate, closeDate),
      updatedAt: DateTime.now().toIso8601String(),
      totalVoters: totalVoters,
    );

    final nextPolls = polls.map((poll) => poll.id == pollId ? updated : poll).toList();
    await _writeLocalPolls(nextPolls);

    final db = FirestoreDataService.instance;
    if (db != null) {
      await db.collection(_pollCollection).doc(updated.id).set(
        updated.toJson(),
        SetOptions(merge: true),
      );
    }

    return updated;
  }

  Future<PollModel?> publishPoll(String pollId) async {
    return _updatePollStatus(pollId, 'active');
  }

  Future<PollModel?> closePoll(String pollId) async {
    return _updatePollStatus(pollId, 'closed');
  }

  Future<PollModel?> archivePoll(String pollId) async {
    return _updatePollStatus(pollId, 'archived');
  }

  Future<void> deletePoll(String pollId) async {
    final polls = await loadPolls();
    final nextPolls = polls.where((poll) => poll.id != pollId).toList();
    await _writeLocalPolls(nextPolls);

    final db = FirestoreDataService.instance;
    if (db != null) {
      await db.collection(_pollCollection).doc(pollId).delete();
    }
  }

  Future<PollModel?> _updatePollStatus(String pollId, String status) async {
    final polls = await loadPolls();
    PollModel? updated;
    final nextPolls = polls.map((poll) {
      if (poll.id != pollId) {
        return poll;
      }

      updated = poll.copyWith(
        status: status,
        updatedAt: DateTime.now().toIso8601String(),
      );
      return updated!;
    }).toList();

    if (updated == null) {
      return null;
    }

    await _writeLocalPolls(nextPolls);

    final db = FirestoreDataService.instance;
    if (db != null) {
      await db.collection(_pollCollection).doc(updated!.id).set(
        updated!.toJson(),
        SetOptions(merge: true),
      );
    }

    return updated;
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

  List<PollModel> _filterByCommuneScope(List<PollModel> polls, String communeScope) {
    if (communeScope.isEmpty) {
      return polls;
    }

    return polls.where((poll) {
      if (poll.communeId.isNotEmpty) {
        return poll.communeId == communeScope;
      }
      if (poll.communeName.isNotEmpty) {
        return poll.communeName.toLowerCase() == communeScope.toLowerCase();
      }
      return true;
    }).toList();
  }
}
