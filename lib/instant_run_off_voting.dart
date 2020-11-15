class Candidate {}

class InstantRunOffVoting<T extends Candidate> {
  final Set<T> _candidates = {};

  final double minimumToWin = 0.5;

  final int maxRounds;

  InstantRunOffVoting({this.maxRounds = 999});

  bool get isPluralityVoting => maxRounds == 0;

  Iterable<ProgressReport<T>> vote(List<Voter<T>> voters) sync* {
    _candidates.clear();
    _candidates.addAll(voters.expand((v) => v.votes));

    /// Start of the process. Nobody has any votes.
    var progress = ProgressReport<T>(
      0,
      false,
      {for (final candidate in _candidates) candidate: 0},
      [],
      [],
      {},
      null,
      null,
    );
    yield progress;

    // Start counting votes. This is just for the effect of "increasing"
    // vote numbers.
    {
      final currentResults = <T, int>{};
      for (final voter in voters) {
        // Tally just the first votes.
        currentResults.update(voter.votes.first, (value) => value + 1,
            ifAbsent: () => 1);
        yield ProgressReport<T>(
          0,
          false,
          {
            for (final candidate in currentResults.keys)
              candidate: currentResults[candidate]!
          },
          [],
          [],
          {},
          Pair(voter, voter.votes.first),
          null,
        );
      }
    }

    if (maxRounds == 0) {
      // Plurality voting.
      // Count votes.
      final currentResults = <T, int>{};
      for (final voter in voters) {
        for (final vote in voter.votes) {
          currentResults.update(vote, (value) => value + 1, ifAbsent: () => 1);
          break;
        }
      }

      T? best;
      var bestVotes = -1;
      for (var candidate in currentResults.keys) {
        final votes = currentResults[candidate]!;
        if (votes > bestVotes) {
          best = candidate;
          bestVotes = votes;
        }
      }

      // Report plurality result.
      yield ProgressReport<T>(
        1,
        true,
        {
          for (final candidate in currentResults.keys)
            candidate: currentResults[candidate]!
        },
        [],
        [],
        _computeHappyVoters(best, voters),
        null,
        best,
      );
    }

    var round = 1;
    var eliminated = <T>[];
    var eliminatedLastRound = <T>[];
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

      T? best;
      var bestVotes = -1;
      var worstVotes = 0x8000000000000000;
      for (final candidate in currentResults.keys) {
        final currentVotes = currentResults[candidate]!;
        if (currentVotes > bestVotes) {
          bestVotes = currentVotes;
          best = candidate;
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
      progress = ProgressReport(
        round,
        isFinished,
        currentResults,
        worstCandidates,
        eliminatedLastRound,
        isFinished ? _computeHappyVoters(best, voters) : {},
        null,
        isFinished ? best : null,
      );
      yield progress;
      round += 1;

      eliminatedLastRound = worstCandidates;
    }
  }

  Map<Voter<T>, bool> _computeHappyVoters(T? best, List<Voter<T>> voters) {
    final result = <Voter<T>, bool>{};
    for (var voter in voters) {
      result[voter] = voter.votes.contains(best);
    }
    return result;
  }
}

class Pair<T, V> {
  final T a;
  final V b;

  const Pair(this.a, this.b);
}

class ProgressReport<T extends Candidate> {
  final int round;

  final bool isFinished;

  final T? winner;

  final Map<T, int> results;

  final List<T> worstThisRound;

  final List<T> eliminatedLastRound;

  final Map<Voter<T>, bool> happyVoters;

  final Pair<Voter<T>, T>? givenVote;

  ProgressReport(this.round, this.isFinished, this.results, this.worstThisRound,
      this.eliminatedLastRound, this.happyVoters, this.givenVote, this.winner);

  @override
  String toString() {
    return 'Progress:\n'
        '  round $round\n'
        '  ${isFinished ? 'finished' : 'not finished'}\n'
        '  $results\n'
        '  to be eliminated: $worstThisRound\n'
        '  eliminated last round: $eliminatedLastRound';
  }
}

class Voter<T extends Candidate> {
  List<T> votes = [];

  final String? name;

  final bool feminine;

  Voter({this.name, this.feminine = false});
}
