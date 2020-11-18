import 'dart:async';
import 'dart:html';

import 'package:async/async.dart';
import 'package:instant_run_off_voting/instant_run_off_voting.dart';

Future<void> main() async {
  final hogofogo = _StringCandidate('Hogofogo'); //  🍸
  final restyka = _StringCandidate('Reštyka'); //  🍷
  final kafe = _StringCandidate('Kafe'); // ☕️
  final pivko = _StringCandidate('Pivko'); // 🍺

  final runOffVoters = [
    Voter(name: 'Eva 👩🏻‍🦰', feminine: true)..votes = [hogofogo, kafe, pivko],
    Voter(name: 'Jana 👧🏻', feminine: true)..votes = [pivko, kafe, restyka],
    Voter(name: 'Honza 👨🏽‍🦳')..votes = [hogofogo, restyka, kafe],
    Voter(name: 'Karel 🧔🏽')..votes = [restyka, pivko, kafe],
    Voter(name: 'Tomáš 👨🏻')..votes = [kafe, pivko, restyka],
  ];

  final maznak = _StringCandidate('Mažňák');
  final tleskac = _StringCandidate('Tleskač');
  final losna = _StringCandidate('Losna');
  final dusin = _StringCandidate('Dušín');

  final bunchOfVoters = <Voter>[
    Voter()..votes = [maznak, tleskac],
    Voter()..votes = [losna, tleskac],
    Voter()..votes = [tleskac, maznak],
    Voter()..votes = [losna, tleskac],
    Voter()..votes = [tleskac, losna, dusin],
  ]..shuffle();

  final plurality = VotingEmbed(
    querySelector('#plurality') as DivElement,
    InstantRunOffVoting(maxRounds: 0),
    runOffVoters,
  );

  await plurality.init();

  final irv = VotingEmbed(
    querySelector('#instant') as DivElement,
    InstantRunOffVoting(),
    runOffVoters,
  );

  await irv.init();

  final serious = VotingEmbed(
    querySelector('#serious') as DivElement,
    InstantRunOffVoting(),
    bunchOfVoters,
    votersInput: true,
  );

  await serious.init();
}

class VotingEmbed<T extends Candidate> {
  final UListElement _logElement;

  final ButtonElement? _playButton;

  final ButtonElement? _stepButton;

  final TableElement _barGraphElement;

  final TextAreaElement? _votersInput;

  final InstantRunOffVoting<T> _voting;

  late final StreamQueue<void> _stepAheadQueue =
      StreamQueue<void>(_stepAhead.stream);

  bool isFinished = false;

  final StreamController<void> _stepAhead = StreamController();

  List<Voter<T>> _voters;

  VotingEmbed(DivElement element, this._voting, this._voters,
      {bool votersInput = false})
      : _logElement = element.querySelector('.log') as UListElement,
        _barGraphElement = element.querySelector('.bargraph') as TableElement,
        _playButton = element.querySelector('.start_button') as ButtonElement?,
        _stepButton = element.querySelector('.step_button') as ButtonElement?,
        _votersInput = votersInput
            ? element.querySelector('.voters-input') as TextAreaElement
            : null,
        _maxVotes = _voters.length;

  Future<void> init() async {
    _playButton?.onClick.listen((event) {
      if (isFinished) {
        _setUpUI(_progress!.first);
        _walkThroughSteps();
        isFinished = false;
      }

      // The first impulse (so that we parse voters).
      _stepAhead.add(null);
      _stepDuration = Duration(milliseconds: (2000 / _maxVotes).ceil());
      Timer.periodic(_stepDuration, (timer) {
        if (isFinished || _voters.isEmpty) {
          // Stop the timer if we've finished or if the input is invalid.
          timer.cancel();
          isFinished = true;
          return;
        }
        _stepAhead.add(null);
      });
    });
    _stepButton?.onClick.listen((event) {
      _stepAhead.add(event);
    });
    _progress = _voting.vote(_voters).toList();
    _setUpUI(_progress!.first);
    _walkThroughSteps();
  }

  List<ProgressReport<T>>? _progress;

  /// This is the maximum votes we expect a candidate will get. We use it for
  /// scaling the bar charts.
  int _maxVotes;

  Duration _stepDuration = const Duration(milliseconds: 16);

  void _walkThroughSteps() async {
    // Wait until the first "step".
    await _stepAheadQueue.next;

    _playButton?.disabled = true;
    _logElement.children.clear();
    _logElement.children.add(Element.li()
      ..text = 'Všichni na značkách. Zde sledujte průběh hlasování.');

    if (_votersInput != null) {
      final votersCSV = _votersInput!.value;
      _voters = _parseVoters(votersCSV!);
      if (_voters.isEmpty) {
        window.alert('Žádní voliči nepřišli.');
        _playButton?.disabled = false;
        return;
      }
      _maxVotes = _voters.length;
      _progress = _voting.vote(_voters).toList();
      _setUpUI(_progress!.first);
    }

    for (final report in _progress!.skip(1)) {
      await _updateUI(report);
    }

    assert(_progress!.last.happyVoters.isNotEmpty);

    for (var voter in _voters) {
      _showHappiness(voter, _progress!.last.happyVoters[voter]!);
      _logElement.scrollTop = _logElement.scrollHeight;
      await _stepAheadQueue.next;
    }
    final percentage = 1 -
        _progress!.last.happyVoters.entries
                .where((element) => element.value)
                .length /
            _voters.length;
    _logElement.children.add(Element.li()
      ..text = '${(percentage * 100).round()} % voličů je nespokojených.');
    _logElement.scrollTop = _logElement.scrollHeight;

    _playButton?.disabled = false;
    _stepButton?.disabled = true;
    isFinished = true;
  }

  final Map<T, SpanElement> _bars = {};

  final Map<T, TableCellElement> _countCells = {};

  final Map<T, TableRowElement> _tableRows = {};

  void _setUpUI(ProgressReport<T> initial) {
    assert(initial.round == 0);
    _bars.clear();
    _countCells.clear();
    _tableRows.clear();
    _barGraphElement.children.clear();
    final headRow = _barGraphElement.addRow();
    headRow.children.add(Element.th()..text = 'Restaurace');
    headRow.children.add(Element.th());
    headRow.children.add(Element.th()..text = 'Hlasy');
    for (var candidate in initial.results.keys) {
      final row = _barGraphElement.addRow();
      _tableRows[candidate] = row;

      row.addCell().text = candidate.toString();

      final countCell = row.addCell()
        ..classes.add('count_cell')
        ..text = '0';
      _countCells[candidate] = countCell;

      final bar = SpanElement()
        ..classes.add('bar')
        ..style.width = '1px'
        ..text = '0';
      _bars[candidate] = bar;
      final barWrapper = DivElement()..classes.add('progress-bar');
      barWrapper.children.add(bar);

      final barCell = row.addCell();
      barCell.children.add(barWrapper);
    }
  }

  Future<void> _updateUI(ProgressReport<T> report) async {
    // Update bar graph for each candidate.
    for (var candidate in report.results.keys) {
      final isEliminated = report.eliminatedLastRound.contains(candidate);
      final isWinner = report.isFinished && report.winner == candidate;
      final countCell = _countCells[candidate]!;
      final bar = _bars[candidate]!;
      final votes = report.results[candidate]!;
      countCell.text = votes.toString();
      String width;
      if (votes == 0) {
        width = '1px';
      } else {
        width = '${votes / _maxVotes * 100}%';
      }
      bar.style.width = width;
      bar.style.backgroundColor = isEliminated ? 'gray' : 'blue';
      if (isWinner) {
        _tableRows[candidate]!.classes.add('winner');
      }
    }

    await _updateLog(report);
  }

  void _showHappiness(Voter<T> voter, bool happyVoter) {
    final element = Element.li()
      ..innerHtml = '${voter.name} '
          'je '
          '${happyVoter ? '' : 'ne'}spokojen${voter.feminine ? 'á' : 'ý'}. '
          '<em>${happyVoter ? '😀' : '😡'}</em>';
    _logElement.children.add(element);
  }

  Future<void> _updateLog(ProgressReport<T> report) async {
    Future<void> add(String message) async {
      _logElement.children.add(Element.li()..innerHtml = message);
      _logElement.scrollTop = _logElement.scrollHeight;
      await _stepAheadQueue.next;
    }

    if (report.givenVote != null) {
      final voter = report.givenVote!.a;
      final firstVote = voter.votes.first;
      final otherVotes = voter.votes.sublist(1);

      final buf = StringBuffer();
      buf.write(
          '${voter.name} hlasoval${voter.feminine ? 'a' : ''} pro restauraci '
          '${firstVote}');
      if (otherVotes.isNotEmpty) {
        if (_voting.isPluralityVoting) {
          buf.write(' (ale nevadil${otherVotes.length > 1 ? 'y' : 'a'} by '
              '${voter.feminine ? 'jí' : 'mu'} ani '
              'restaurace ${otherVotes.join(' nebo ')})');
        } else {
          buf.write(' v prvé řadě, ale dále také pro restaurace '
              '${otherVotes.join(' a ')}');
        }
      }
      buf.write('.');

      await add(buf.toString());
      return;
    }

    if (report.round > 0) {
      await add('Současný stav: ${report.results}.');
    }

    if (report.isFinished) {
      await add('<strong>Je rozhodnuto!</strong> '
          'Vyhrává restaurace <strong>${report.winner!}</strong>. '
          '(Klikejte dál, abyste zjistili, '
          'jak jsou lidé spokojení s výsledkem.)');
      return;
    }

    if (report.worstThisRound.isNotEmpty) {
      assert(report.worstThisRound.length == 1);
      await add('Restaurace ${report.worstThisRound.single} má moc málo hlasů. '
          'Vypadává. Hlasy lidí, co pro ni hlasovali, se přemístí do jejich '
          'druhé či třetí oblíbené volby.');
    }
  }

  List<Voter<T>> _parseVoters(String string) {
    final result = <Voter<_StringCandidate>>[];

    var i = 1;
    final lines =
        string.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
    for (var line in lines) {
      final voteStrings =
          line.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      final votes = <_StringCandidate>[
        for (var vote in voteStrings) _StringCandidate(vote),
      ];
      result.add(Voter(name: 'Volič ${i++}')..votes = votes);
    }
    return result as List<Voter<T>>;
  }
}

class _StringCandidate extends Candidate {
  final String name;

  _StringCandidate(this.name);

  @override
  String toString() {
    return '$name';
  }

  @override
  bool operator ==(Object other) {
    return other is _StringCandidate && name == other.name;
  }

  @override
  int get hashCode => name.hashCode;
}
