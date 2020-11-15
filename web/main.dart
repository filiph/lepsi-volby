import 'dart:html';

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
  final mirek = _StringCandidate('Mirek');

  final bunchOfVoters = <Voter>[
    for (var i = 0; i < 200; i++) Voter()..votes = [maznak],
    for (var i = 0; i < 200; i++) Voter()..votes = [maznak, tleskac],
    for (var i = 0; i < 150; i++) Voter()..votes = [tleskac, mirek],
    for (var i = 0; i < 200; i++) Voter()..votes = [tleskac, mirek, losna],
    for (var i = 0; i < 200; i++) Voter()..votes = [mirek, losna],
    for (var i = 0; i < 100; i++) Voter()..votes = [mirek, tleskac, losna],
    for (var i = 0; i < 100; i++) Voter()..votes = [losna, tleskac],
    for (var i = 0; i < 100; i++) Voter()..votes = [losna, mirek],
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
  );

  await serious.init();
}

class VotingEmbed<T extends Candidate> {
  final UListElement _logElement;

  final ButtonElement _buttonElement;

  final DivElement _happinessElement;

  final TableElement _barGraphElement;

  final InstantRunOffVoting<T> _voting;

  final List<Voter<T>> _voters;

  VotingEmbed(DivElement element, this._voting, this._voters)
      : _logElement = element.querySelector('.log') as UListElement,
        _happinessElement = element.querySelector('.happiness') as DivElement,
        _barGraphElement = element.querySelector('.bargraph') as TableElement,
        _buttonElement =
            element.querySelector('.start_button') as ButtonElement,
        maxVotes = _voters.length;

  Future<void> init() async {
    _buttonElement.onClick.listen((event) {
      _handleStart();
      _buttonElement.disabled = true;
    });
    _progress = _voting.vote(_voters).toList();
    _setUpUI(_progress!.first);
  }

  List<ProgressReport<T>>? _progress;

  /// This is the maximum votes we expect a candidate will get. We use it for
  /// scaling the bar charts.
  final int maxVotes;

  final Duration _stepDuration = const Duration(milliseconds: 400);

  void _handleStart() async {
    _logElement.children.clear();
    _happinessElement.children.clear();

    for (final report in _progress!) {
      if (report.isFinished) {
        // Extra wait for dramatic effect.
        await Future.delayed(_stepDuration);
      }
      _updateUI(report);
      await Future.delayed(_stepDuration);
    }

    await Future.delayed(_stepDuration);
    assert(_progress!.last.happyVoters.isNotEmpty);

    await Future.delayed(_stepDuration);
    await Future.delayed(_stepDuration);
    _logElement.children
        .add(Element.li()..text = 'Jak jsou lidé spokojení s výsledkem?');
    _logElement.scrollTop = _logElement.scrollHeight;
    await Future.delayed(_stepDuration);
    await Future.delayed(_stepDuration);
    await Future.delayed(_stepDuration);
    for (var voter in _voters) {
      _showHappiness(voter, _progress!.last.happyVoters[voter]!);
      _logElement.scrollTop = _logElement.scrollHeight;
      await Future.delayed(_stepDuration);
    }
    _buttonElement.disabled = false;
  }

  final Map<T, SpanElement> _bars = {};

  final Map<T, TableCellElement> _countCells = {};

  final Map<T, TableRowElement> _tableRows = {};

  void _setUpUI(ProgressReport<T> initial) {
    assert(initial.round == 0);
    _bars.clear();
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

  void _updateUI(ProgressReport<T> report) {
    for (var candidate in report.results.keys) {
      final isEliminated = report.worstThisRound.contains(candidate);
      final isWinner = report.isFinished && report.winner == candidate;
      final countCell = _countCells[candidate]!;
      final bar = _bars[candidate]!;
      final votes = report.results[candidate]!;
      countCell.text = votes.toString();
      String width;
      if (votes == 0) {
        width = '1px';
      } else {
        width = '${votes / maxVotes * 100}%';
      }
      bar.style.width = width;
      bar.style.backgroundColor = isEliminated ? 'gray' : 'blue';
      if (isWinner) {
        _tableRows[candidate]!.classes.add('winner');
      }
    }

    _updateLog(report);
    _logElement.scrollTop = _logElement.scrollHeight;
  }

  void _showHappiness(Voter<T> voter, bool happyVoter) {
    final element = Element.li()
      ..innerHtml = '${voter.name} '
          'je '
          '${happyVoter ? '' : 'ne'}spokojen${voter.feminine ? 'á' : 'ý'}. '
          '<em>${happyVoter ? '😀' : '😡'}</em>';
    _logElement.children.add(element);
  }

  void _updateLog(ProgressReport<T> report) {
    void add(String message) {
      _logElement.children.add(Element.li()..innerHtml = message);
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
          buf.write(' (ale dal${voter.feminine ? 'a' : ''} by za vděk '
              'také restauracím ${otherVotes.join(' nebo ')})');
        } else {
          buf.write(' v prvé řadě, ale dále také pro restaurace '
              '${otherVotes.join(' a ')}');
        }
      }
      buf.write('.');

      add(buf.toString());
      return;
    }

    if (report.worstThisRound.isNotEmpty) {
      assert(report.worstThisRound.length == 1);
      add('Restaurace ${report.worstThisRound.single} má moc málo hlasů. '
          'Vypadává. Hlasy lidí, co pro ni hlasovali, se přemístí do jejich '
          'druhé či třetí oblíbené volby.');
    }

    if (report.isFinished) {
      add('<strong>Je rozhodnuto!</strong> '
          'Vyhrává restaurace <strong>${report.winner!}</strong>.');
      return;
    }
  }
}

class _StringCandidate extends Candidate {
  final String name;

  _StringCandidate(this.name);

  @override
  String toString() {
    return '$name';
  }
}
