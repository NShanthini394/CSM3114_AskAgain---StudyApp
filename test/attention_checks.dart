import 'dart:io';

import 'package:askagain/data/attention.dart';
import 'package:askagain/data/study_content.dart';
import 'package:askagain/data/study_languages.dart';

void main() {
  void check(bool ok, String label) {
    if (!ok) throw StateError(label);
    stdout.writeln('PASS $label');
  }

  final questions = <ContentRecord>[
    {
      'id': 'a',
      'subject': 'math',
      'chapter': 'algebra',
      'prompt': 'Solve for x.',
      'answer': 'x = 2',
      'rating': 1,
    },
    {
      'id': 'b',
      'subject': 'science',
      'chapter': 'cells',
      'prompt': 'Define a cell.',
      'answer': 'The basic unit of life.',
    },
  ];
  ContentRecord attempt(String id, String reason, int day) => {
    'question': id,
    'mistake': reason,
    'timestamp': '2026-11-${day.toString().padLeft(2, '0')}T12:00:00Z',
  };
  check(
    attentionGroups(questions, []).isEmpty,
    'No history produces no flagged questions',
  );
  final repeated = attentionGroups(questions, [
    attempt('a', 'Confused concepts', 1),
    attempt('a', 'Confused concepts', 2),
  ]);
  check(
    repeated.single.questions.length == 1,
    'Repeated mistakes count a question only once',
  );
  final newest = attentionGroups(questions, [
    attempt('a', 'Wrong formula', 4),
    attempt('a', 'Confused concepts', 2),
  ]);
  check(
    newest.single.reason == 'Wrong formula',
    'Latest timestamp wins even with unordered history',
  );
  check(
    attentionGroups(questions, [
      attempt('a', 'Confused concepts', 1),
      attempt('a', '', 2),
    ]).isEmpty,
    'A new practice attempt without a difficulty clears the previous one',
  );
  check(
    attentionGroups(questions, [
          attempt('a', 'Confused concepts', 1),
          {...attempt('a', '', 2), 'activity': 'recall'},
        ]).single.reason ==
        'Confused concepts',
    'Learn and Recall does not silently erase a recorded practice difficulty',
  );
  check(
    attentionGroups(
      [
        {...questions.first, 'rating': 3},
      ],
      [attempt('a', 'Confused concepts', 1)],
    ).isEmpty,
    'Mastered questions leave the attention list',
  );
  check(
    attentionGroups(questions, [attempt('deleted', 'Forgot', 1)]).isEmpty,
    'Removed questions cannot leave broken attention links',
  );
  check(
    attentionGroups(
      [
        {...questions.first, 'approved': false},
      ],
      [attempt('a', 'Forgot', 1)],
    ).isEmpty,
    'Unapproved drafts are excluded',
  );
  final matching = {
    ...attempt('a', 'Confused concepts', 2),
    'questionIds': ['a', 'b', 'a'],
  };
  final group = attentionGroups(questions, [matching]).single;
  check(
    group.questions.length == 2,
    'Matching difficulties link every distinct source question',
  );
  check(
    group.questions.map((q) => q['subject']).toSet().length == 2,
    'Categories retain questions from multiple subjects',
  );
  check(
    attemptedQuestionIds(attempt('a', 'Forgot', 1)).single == 'a',
    'Existing attempt records retain their question links',
  );
  check(
    attemptedQuestionIds({'questionIds': [], 'question': 'a'}).single == 'a',
    'Empty source lists fall back to the existing question reference',
  );
  check(
    attentionGroups(questions, [
          {'question': 'a', 'date': '2026-11-02', 'mistake': 'Forgot'},
          {'question': 'a', 'date': '2026-11-01', 'mistake': 'Wrong formula'},
        ]).single.reason ==
        'Forgot',
    'Older history without timestamps uses its recorded dates',
  );
  check(
    attentionGroups(questions, [
          matching,
          attempt('a', '', 3),
        ]).single.questions.single['id'] ==
        'b',
    'Resolving one matching source leaves the other question flagged',
  );
  check(
    scopedQuestions(questions, null, null, questionIds: {'b'}).single['id'] ==
        'b',
    'Attention sessions include exactly the requested questions across subjects',
  );
  check(
    scopedQuestions(questions, 'math', null, questionIds: {'b'}).isEmpty,
    'A filtered session cannot leak questions outside its subject',
  );
  check(
    scopedQuestions(questions, null, null, questionIds: {}).isEmpty,
    'An empty attention selection cannot open the full bank',
  );
  check(
    generationLanguageInstruction(null).contains('supporting source passage') &&
        generationLanguageInstruction('Same as uploaded notes')
            .contains('multilingual'),
    'Default generation explicitly follows each supporting passage language',
  );
  check(
    generationLanguageInstruction('Tamil')
            .contains('both questions and answers in Tamil') &&
        generationLanguageInstruction('Tamil')
            .contains('original source language'),
    'Optional translation covers Q&A while retaining original evidence',
  );
}
