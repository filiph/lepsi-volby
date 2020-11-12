class InstantRunOffVoting<T extends Candidate> {
  final Set<T> _candidates = {};

  final double minimumToWin = 0.5;

  final int maxRounds = 10;

  InstantRunOffVoting();

  Iterable<ProgressReport<T>> vote(List<Voter<T>> voters) sync* {
    _candidates.clear();
    _candidates.addAll(voters.expand((v) => v.votes));

    var progress = ProgressReport<T>(
      0,
      false,
      {
        for (final candidate in _candidates) candidate: 0,
      },
      [],
    );
    yield progress;

    var round = 1;
    var eliminated = <T>[];
    while (!progress.isFinished && round <= maxRounds) {
      // Count votes.
      final currentResults = <T, int>{};
      for (final voter in voters) {
        for (final vote in voter.votes) {
          if (eliminated.contains(vote)) continue;
          currentResults.update(vote, (value) => value + 1, ifAbsent: () => 1);
          break;
        }
      }

      var bestVotes = -1;
      var worstVotes = 0x8000000000000000;
      for (final candidate in currentResults.keys) {
        final currentVotes = currentResults[candidate]!;
        if (currentVotes > bestVotes) {
          bestVotes = currentVotes;
        }
        if (currentVotes < worstVotes) {
          worstVotes = currentVotes;
        }
      }
      final survivingCandidates =
          _candidates.difference(Set.from(eliminated)).toList();

      // There could be more than one candidate with least amount of votes.
      // (A tie in the last place.)
      final worstCandidates = survivingCandidates
          .where((candidate) => currentResults[candidate] == worstVotes)
          // TODO: this is a temporary hack - we should resolve tiebreaks
          .take(1)
          .toList();
      eliminated.addAll(worstCandidates);

      final isFinished = survivingCandidates.length == 1 ||
          bestVotes / voters.length > minimumToWin;
      progress =
          ProgressReport(round, isFinished, currentResults, worstCandidates);
      yield progress;
      round += 1;
    }
  }
}

class ProgressReport<T extends Candidate> {
  final int round;

  final bool isFinished;

  final Map<T, int> results;

  final List<T> worst;

  ProgressReport(this.round, this.isFinished, this.results, this.worst);

  @override
  String toString() {
    return 'Progress:\n'
        '  round $round\n'
        '  ${isFinished ? 'finished' : 'not finished'}\n'
        '  $results\n'
        '  to be eliminated: $worst';
  }
}

class Candidate {}

class Voter<T extends Candidate> {
  List<T> votes = [];
}
