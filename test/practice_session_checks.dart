import 'dart:io';
import 'dart:math';

import 'package:askagain/data/practice_session.dart';
import 'package:askagain/data/study_content.dart';
import 'package:askagain/data/study_languages.dart';

void main() {
  var count = 0;
  void check(bool ok, String name) {
    if (!ok) throw StateError(name);
    count++;
    stdout.writeln('PASS $name');
  }

  List<ContentRecord> bank(int n) => List.generate(
    n,
    (i) => {
      'id': 'q$i',
      'subject': 's',
      'chapter': i.isEven ? 'c1' : 'c2',
      'prompt': 'What is item $i?',
      'answer': 'Definition of item $i.',
      'mode': 'Theory',
    },
  );
  final source = bank(10);
  final originalOrder = source.map((q) => q['id']).join(',');
  final written = buildPracticePlan(
    source,
    'Written / problem solving',
    random: Random(7),
  );
  check(
    written.included == 10 && written.questions.length == 10,
    'Written practice includes every question in scope',
  );
  check(
    written.questions.map((q) => q['id']).toSet().length == 10,
    'Shuffling never duplicates or drops questions',
  );
  check(
    source.map((q) => q['id']).join(',') == originalOrder,
    'Session preparation preserves the stored bank order',
  );
  final previous = written.questions.map((q) => q['id'].toString()).toList();
  final repeated = buildPracticePlan(
    source,
    'Written / problem solving',
    random: Random(7),
    previous: previous,
  );
  check(
    repeated.questions.map((q) => q['id']).join(',') != previous.join(','),
    'Repeated sessions change order even when random output repeats',
  );
  check(
    buildPracticePlan(
          source.take(1).toList(),
          'Written / problem solving',
        ).questions.length ==
        1,
    'A one-question bank remains usable',
  );
  for (var n = 2; n <= 20; n++) {
    final plan = buildPracticePlan(bank(n), 'Matching', random: Random(n));
    final ids = plan.questions.expand((q) => q['_sourceIds'] as List).toList();
    check(
      ids.length == n &&
          ids.toSet().length == n &&
          plan.questions.every(
            (q) =>
                (q['pairs'] as List).length >= 2 &&
                (q['pairs'] as List).length <= 4,
          ),
      'Matching covers all $n questions in rounds of 2–4 without singleton rounds',
    );
  }
  final duplicate = [
    ...bank(3),
    {
      'id': 'duplicate',
      'prompt': 'Another question',
      'answer': 'Definition of item 0.',
      'subject': 's',
      'mode': 'Theory',
    },
  ];
  final matching = buildPracticePlan(duplicate, 'Matching');
  check(
    matching.included == 3 &&
        matching.total == 4 &&
        matching.message.isNotEmpty,
    'Excluded duplicate matching answers are reported',
  );
  check(
    buildPracticePlan(bank(1), 'Matching').questions.isEmpty,
    'One eligible question reports matching is unavailable',
  );
  final mixed = [
    ...bank(3),
    {
      'id': 'code',
      'subject': 's',
      'prompt': 'Write code',
      'answer': 'return item;',
      'mode': 'Programming',
    },
    {
      'id': 'num',
      'subject': 's',
      'prompt': 'Calculate',
      'answer': '42',
      'numeric': 42,
    },
  ];
  final blanks = buildPracticePlan(
    mixed,
    'Fill in the blanks',
    random: Random(12),
  );
  check(
    blanks.included == 3 && blanks.total == 5 && blanks.message.isNotEmpty,
    'Blank practice includes all suitable text answers and reports skipped code and calculations',
  );
  check(
    blanks.questions.every(
      (q) => q['prompt'].contains('___') && (q['blanks'] as List).isNotEmpty,
    ),
    'Every automatic blank exercise has its answer key',
  );
  final blankIds = blanks.questions.map((q) => q['id'].toString()).toList();
  final repeatedBlanks = buildPracticePlan(
    mixed,
    'Fill in the blanks',
    random: Random(12),
    previous: blankIds,
  );
  check(
    repeatedBlanks.questions.map((q) => q['id']).join(',') !=
        blankIds.join(','),
    'Filtered practice changes order between sessions',
  );
  final chapter = scopedQuestions(source, 's', 'c1');
  check(
    buildPracticePlan(
      chapter,
      'Written / problem solving',
    ).questions.every((q) => q['chapter'] == 'c1'),
    'Chapter practice cannot include another chapter',
  );
  check(
    recallCompletion(5, 10) == .5 &&
        recallCompletion(10, 10) == 1 &&
        recallCompletion(0, 0) == 0,
    'Recall progress counts completed cards and handles empty sessions',
  );
  check(
    recallRating(0) == 2 && recallRating(1) == 1 && recallRating(2) == 0,
    'Three recall buttons map to scheduling ratings without declaring instant mastery',
  );
  check(
    writtenQuestion({
          'prompt': '___ is a term',
          'studyPrompt': 'Define the term',
          'answer': 'Example',
          'responseFormat': 'Fill in the blanks',
        })['prompt'] ==
        'Define the term',
    'Written practice uses the original question when available',
  );
  check(
    normaliseStudyLanguage('Malay') == 'Bahasa Melayu' &&
        normaliseStudyLanguage('Chinese') == 'Simplified Chinese',
    'Existing language names migrate to the supported labels',
  );
  check(
    normaliseStudyLanguage('Same as notes') == 'Same as uploaded notes',
    'Legacy source-language preference remains valid',
  );
  check(
    availableStudyLanguages('French').contains('French') &&
        availableStudyLanguages('English').length == 5,
    'Legacy preferences remain available without duplicating supported languages',
  );
  stdout.writeln('$count practice and language checks passed.');
}
