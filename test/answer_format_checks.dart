import 'dart:io';

import 'package:askagain/data/answer_formats.dart';

void main() {
  void check(bool value, String name) {
    if (!value) throw StateError(name);
    stdout.writeln('PASS $name');
  }

  final blank = {
    'prompt': '___ uses ___ memory.',
    'responseFormat': 'Fill in the blanks',
    'blanks': blankAnswers('CPU | Central processing unit\nRAM'),
  };
  check(
    validateResponse(blank) == null,
    'Two blanks accept exactly two answer groups',
  );
  check(
    scoreBlanks(blank['blanks'] as List, [
          ' central  processing unit ',
          'ram',
        ]) ==
        2,
    'Accepted alternatives ignore letter case and repeated spaces',
  );
  check(
    scoreBlanks(blank['blanks'] as List, ['CPU', 'ROM']) == 1,
    'A wrong answer reduces the score',
  );
  check(
    validateResponse({...blank, 'prompt': 'A question without blanks'}) != null,
    'Blank format requires visible placeholders',
  );
  check(
    validateResponse({
          ...blank,
          'blanks': [
            ['CPU'],
          ],
        }) !=
        null,
    'A missing accepted answer is rejected',
  );
  final pairs = matchingPairs(
    'CPU = Processor\nRAM = Working memory\nSSD = Storage',
  );
  check(
    validateResponse({'responseFormat': 'Matching', 'pairs': pairs}) == null,
    'Three matching pairs are valid',
  );
  check(
    scoreMatching(pairs, {0: 0, 1: 2, 2: 1}) == 1,
    'Matching is scored against the pair identity after shuffling',
  );
  check(
    validateResponse({
          'responseFormat': 'Matching',
          'pairs': matchingPairs('A = X\nB = X'),
        }) !=
        null,
    'Duplicate answer options are rejected',
  );
  check(
    validateResponse({
          'responseFormat': 'Matching',
          'pairs': matchingPairs('Invalid line\nB = Y'),
        }) !=
        null,
    'Malformed pairs are rejected',
  );
  check(
    responseFormat({'mode': 'Programming'}) == 'Code answer' &&
        responseFormat({'numeric': 3}) == 'Numerical answer' &&
        responseFormat({'mode': 'Theory'}) == 'Written answer',
    'Existing saved questions keep their answer formats',
  );
  check(
    validateResponse({
          'responseFormat': 'Numerical answer',
          'numeric': 'NaN',
        }) !=
        null,
    'Invalid numeric solutions are rejected',
  );
  check(
    validateResponse({
          'responseFormat': 'Numerical answer',
          'numeric': 5,
          'tolerance': 0,
        }) ==
        null,
    'Finite numeric answers accept zero tolerance',
  );
}
