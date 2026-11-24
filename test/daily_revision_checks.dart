import 'dart:io';

import 'package:askagain/data/study_content.dart';
import 'package:askagain/data/practice_session.dart';

void main() {
  void check(bool ok, String label) {
    if (!ok) throw StateError(label);
    stdout.writeln('PASS $label');
  }

  final bank = <ContentRecord>[
    {
      'id': 'overdue',
      'subject': 's',
      'due': '2026-11-19',
      'prompt': 'Define a cell.',
      'answer': 'The basic unit of life.',
    },
    {
      'id': 'today',
      'subject': 's',
      'due': '2026-11-20',
      'prompt': 'Define a tissue.',
      'answer': 'A group of specialised cells.',
    },
    {
      'id': 'future',
      'subject': 's',
      'due': '2026-11-21',
      'prompt': 'Define an organ.',
      'answer': 'A group of tissues.',
    },
  ];
  final due = dueQuestions(bank, '2026-11-20');
  check(
    due.map((q) => q['id']).join(',') == 'overdue,today',
    'Daily revision includes today and overdue questions only',
  );
  check(
    buildPracticePlan(due, 'Written / problem solving').included == 2,
    'Written daily practice includes every due question',
  );
  final blanks = buildPracticePlan(due, 'Fill in the blanks');
  check(
    blanks.questions.every((q) => q['id'] != 'future') && blanks.included == 2,
    'Blank practice cannot pull in future questions',
  );
  final matching = buildPracticePlan(due, 'Matching');
  check(
    (matching.questions.single['_sourceIds'] as List).toSet().containsAll([
          'overdue',
          'today',
        ]) &&
        !(matching.questions.single['_sourceIds'] as List).contains('future'),
    'Matching rounds use only due source questions',
  );
  check(
    dueQuestions(bank.skip(2), '2026-11-20').isEmpty,
    'An empty daily queue cannot fall back to all questions',
  );
  final single = buildPracticePlan(due.take(1).toList(), 'Matching');
  check(
    single.questions.isEmpty && single.message.isNotEmpty,
    'Matching explains when only one due question is available',
  );
  check(
    dueQuestions([
          {'id': 'legacy'},
        ], '2026-11-20').length ==
        1,
    'Older questions without a review date remain available',
  );
  check(
    bank.length == 3 && bank.last['due'] == '2026-11-21',
    'Preparing daily revision leaves the saved bank unchanged',
  );
}
