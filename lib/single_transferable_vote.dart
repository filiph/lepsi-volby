// /// This is taken from https://dart-review.googlesource.com/c/sdk/+/73360.
// int _hashAll(Iterable<Object?> objects) {
//   var hash = 0;
//   for (var object in objects) {
//     hash = _SystemHash.combine(hash, object.hashCode);
//   }
//   return _SystemHash.finish(hash);
// }
//
// class Ballot<T> {
//   final List<T> preference;
//
//   Ballot(this.preference);
//
//   @override
//   int get hashCode => _hashAll(preference);
//
//   @override
//   bool operator ==(Object other) {
//     if (other is! Ballot<T>) return false;
//     if (other.preference.length != preference.length) return false;
//     for (var i = 0; i < preference.length; i++) {
//       if (other.preference[i] != preference[i]) return false;
//     }
//     return true;
//   }
// }
//
// class ElectionReport<T> {
//   final int round;
//
//   final bool isFinishedReceivingBallots;
//
//   final bool isFinishedEvaluating;
//
//   final Map<T, int> results;
//
//   /// The candidates that were eliminated most recently, if any.
//   final List<T> eliminated;
//
//   /* TODO: happy / sad */
//
//   ElectionReport(this.round, this.isFinishedReceivingBallots,
//       this.isFinishedEvaluating, this.results, this.eliminated);
//
//   @override
//   String toString() {
//     return 'Progress:\n'
//         '  round $round\n'
//         '  ${isFinishedReceivingBallots ? 'finished' : 'not finished'} '
//         'receiving ballots\n'
//         '  ${isFinishedEvaluating ? 'finished' : 'not finished'} '
//         'evaluating\n'
//         '  $results\n'
//         '  to be eliminated: $eliminated';
//   }
// }
//
// class SingleTransferableVoting<T> {
//   final int voterCount;
//
//   final int seatsToFill;
//
//   /// Droop quota.
//   ///
//   /// Computed as in Wikipedia's example:
//   /// https://en.wikipedia.org/wiki/Single_transferable_vote#Example
//   final int quota;
//
//   final _ballots = <Ballot<T>, int>{};
//
//   /// The candidates that have been eliminated in one of the previous rounds.
//   final Set<T> _eliminated = {};
//
//   /// The candidates that have won.
//   final Set<T> _winners = {};
//
//   final Map<T, int> _tally = {};
//
//   SingleTransferableVoting(this.voterCount, this.seatsToFill)
//       : quota = (voterCount / (seatsToFill + 1)).floor() + 1;
//
//   ElectionReport<T> cast(Ballot<T> ballot) {
//     if (_ballots.length >= voterCount) {
//       throw StateError('Too many ballots!');
//     }
//     _ballots.update(ballot, (value) => value + 1, ifAbsent: () => 1);
//
//     return ElectionReport<T>(0, false, false, _collapseResults(_ballots), []);
//   }
//
//   int _round = 0;
//
//   /// Move to the next step of voting.
//   ///
//   /// TODO: use Meek's algorithm
//   /// https://www.researchgate.net/publication/31499523_Algorithm_123_Single_Transferable_Vote_by_Meek's_Method
//   ElectionReport<T> step() {
//     if (_ballots.length < voterCount) {
//       throw StateError('Cannot go to next round before all ballots are in.');
//     }
//
//     if (_tally.isEmpty) {
//       return _roundOne();
//     }
//   }
//
//   ElectionReport<T> _roundOne() {
//     assert(_round == 0);
//     _round = 1;
//     _tally.addAll(_collapseResults(_ballots));
//     final firstRoundWinners = <T>{};
//     for (final candidate in _tally.entries) {
//       if (candidate.value >= quota) {
//         // Candidate wins.
//         firstRoundWinners.add(candidate.key);
//         _transferVotesOverQuota(candidate.key, candidate.value - quota);
//       }
//     }
//
//     _winners.addAll(firstRoundWinners);
//   }
//
//   /// Transfers [voteCount] votes from [candidate] to other candidates,
//   /// proportionally to
//   void _transferVotesOverQuota(T candidate, int voteCount) {
//     assert(voteCount >= 0);
//     if (voteCount == 0) return;
//   }
//
//   Map<T, int> _collapseResults(Map<Ballot<T>, int> ballots) {
//     final simpleTally = <T, int>{};
//     for (var ballot in ballots.keys) {
//       final count = ballots[ballot]!;
//       simpleTally.update(
//         ballot.preference.first,
//         (value) => value + count,
//         ifAbsent: () => count,
//       );
//     }
//     return simpleTally;
//   }
// }
//
// /// This is taken from https://dart-review.googlesource.com/c/sdk/+/73360.
// class _SystemHash {
//   static int combine(int hash, int value) {
//     hash = 0x1fffffff & (hash + value);
//     hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
//     return hash ^ (hash >> 6);
//   }
//
//   static int finish(int hash) {
//     hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
//     hash = hash ^ (hash >> 11);
//     return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
//   }
// }
//
// class _Tuple<A, B> {
//   final A first;
//
//   final B second;
//
//   const _Tuple(this.first, this.second);
// }
