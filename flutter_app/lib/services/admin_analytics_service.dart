import '../models/poll_models.dart';
import 'citizen_access_code_service.dart';
import 'citizen_public_access_service.dart';
import 'poll_service.dart';

class PollAccessStats {
  const PollAccessStats({
    required this.pollId,
    required this.pollName,
    required this.total,
    required this.activated,
    required this.voted,
  });

  final String pollId;
  final String pollName;
  final int total;
  final int activated;
  final int voted;
}

class DailyVotesMetric {
  const DailyVotesMetric({required this.label, required this.votes});

  final String label;
  final int votes;
}

class AdminAnalyticsSummary {
  const AdminAnalyticsSummary({
    required this.polls,
    required this.accessStats,
    required this.dailyVotes,
  });

  const AdminAnalyticsSummary.empty()
      : polls = const [],
        accessStats = const [],
        dailyVotes = const [];

  final List<PollModel> polls;
  final List<PollAccessStats> accessStats;
  final List<DailyVotesMetric> dailyVotes;

  int get totalVotes => polls.fold<int>(0, (sum, poll) => sum + poll.totalVoted);

  int get totalVoters => polls.fold<int>(0, (sum, poll) => sum + poll.totalVoters);

  int get activeCount => polls.where((item) => item.status == 'active').length;

  int get closedCount => polls.where((item) => item.status == 'closed').length;

  int get draftCount => polls.where((item) => item.status == 'draft').length;

  int get totalValidatedCodes => accessStats.fold<int>(0, (sum, item) => sum + item.total);

  int get totalActivatedCodes => accessStats.fold<int>(0, (sum, item) => sum + item.activated);

  int get totalUsedCodes => accessStats.fold<int>(0, (sum, item) => sum + item.voted);

  double get averageParticipation {
    final eligiblePolls = polls.where((item) => item.totalVoters > 0).toList();
    if (eligiblePolls.isEmpty) {
      return 0;
    }

    final totalRate = eligiblePolls
        .map((item) => item.totalVoted / item.totalVoters)
        .reduce((left, right) => left + right);
    return (totalRate / eligiblePolls.length) * 100;
  }
}

class AdminAnalyticsService {
  AdminAnalyticsService._();

  static final AdminAnalyticsService instance = AdminAnalyticsService._();

  Future<AdminAnalyticsSummary> loadSummary() async {
    final polls = await PollService.instance.loadPolls();
    final citizenCodes = await CitizenAccessCodeService.instance.loadAccessCodesForCurrentCommune();
    final voteDates = await CitizenPublicAccessService.instance.loadVoteDatesForCurrentCommune();
    final accessStats = <PollAccessStats>[];
    final votesByDay = <String, int>{};

    final activeCodes = citizenCodes.where((item) => item.status == 'active').length;
    final usedCodes = citizenCodes.where((item) => item.usedForLogin).length;
    if (citizenCodes.isNotEmpty) {
      accessStats.add(
        PollAccessStats(
          pollId: 'commune_access',
          pollName: 'Acces citoyens commune',
          total: activeCodes,
          activated: usedCodes,
          voted: polls.fold<int>(0, (sum, poll) => sum + poll.totalVoted),
        ),
      );
    }

    for (final voteDate in voteDates) {
      final key = voteDate.toIso8601String().split('T').first;
      votesByDay[key] = (votesByDay[key] ?? 0) + 1;
    }

    final now = DateTime.now();
    final dailyVotes = List<DailyVotesMetric>.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final key = date.toIso8601String().split('T').first;
      return DailyVotesMetric(
        label: _weekdayLabel(date.weekday),
        votes: votesByDay[key] ?? 0,
      );
    });

    return AdminAnalyticsSummary(
      polls: polls,
      accessStats: accessStats,
      dailyVotes: dailyVotes,
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return labels[(weekday - 1).clamp(0, labels.length - 1)];
  }
}