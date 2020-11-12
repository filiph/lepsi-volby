import 'dart:html';

import 'package:instant_run_off_voting/instant_run_off_voting.dart';

void main() {
  final hogofogo = _StringCandidate('hogofogo');
  final putyka = _StringCandidate('putyka');
  final kafe = _StringCandidate('kafe');
  final pivko = _StringCandidate('pivko');

  final voters = [
    Voter()..votes = [hogofogo, kafe, pivko],
    Voter()..votes = [hogofogo, pivko, putyka],
    Voter()..votes = [pivko, kafe, putyka],
    Voter()..votes = [putyka, pivko, kafe],
    Voter()..votes = [kafe, pivko, putyka],
  ];

  final output = querySelector('#output') as DivElement;

  final voting = InstantRunOffVoting();

  voting.vote(voters).forEach((report) {
    output.children.add(ParagraphElement()..text = '$report');
  });
}

class _StringCandidate extends Candidate {
  final String name;

  _StringCandidate(this.name);

  @override
  String toString() {
    return '$name';
  }
}
