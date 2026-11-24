import 'dart:io';

import 'package:askagain/data/study_content.dart';
import 'package:askagain/data/answer_formats.dart';

void main() {
  var passed = 0;
  void check(bool condition, String name) {
    if (!condition) throw StateError(name);
    passed++;
    stdout.writeln('PASS $name');
  }

  final original = <String, dynamic>{
    'id': 'q',
    'subject': 'bio',
    'chapter': 'c1',
    'prompt': 'What does the CPU do?',
    'answer': 'The CPU processes instructions.',
    'mode': 'Theory',
  };
  final result = makeBlankExercise(original, {1, 3});
  check(
    result['prompt'] == 'The ___ processes ___.',
    'Selected words are hidden without changing punctuation or word order',
  );
  check(
    scoreBlanks(result['blanks'], ['cpu', 'Instructions']) == 2,
    'Automatic answer keys accept common letter casing',
  );
  check(
    original['prompt'] == 'What does the CPU do?' &&
        original['answer'] == 'The CPU processes instructions.',
    'Derived practice preserves the saved Q&A',
  );
  check(
    result['id'] == 'q',
    'Derived blanks keep the source question identity',
  );
  check(
    suggestedBlanks('The CPU processes instructions.').isNotEmpty,
    'Automatic blank selection finds candidate words',
  );
  check(
    suggestedBlanks('is a').isNotEmpty,
    'Short answers have a safe preview fallback',
  );
  check(suggestedBlanks('').isEmpty, 'Empty input has no hidden words');
  var rejected = false;
  try {
    makeBlankExercise(original, {});
  } on ArgumentError {
    rejected = true;
  }
  check(rejected, 'An exercise cannot contain zero blanks');
  final second = <String, dynamic>{
    'id': 'r',
    'subject': 'bio',
    'chapter': 'c2',
    'prompt': 'What is RAM?',
    'answer': 'Working memory.',
    'mode': 'Theory',
  };
  final matching = makeMatchingExercise([original, second]);
  check(
    (matching['pairs'] as List).length == 2 &&
        matching['_sourceIds'].join(',') == 'q,r',
    'Matching uses existing Q&A and retains all source identities',
  );
  check(
    matching['chapter'] == '',
    'Mixed-chapter rounds are identified at subject level',
  );
  rejected = false;
  try {
    makeMatchingExercise([
      original,
      {...second, 'answer': original['answer']},
    ]);
  } on ArgumentError {
    rejected = true;
  }
  check(rejected, 'Duplicate matching answers are rejected');
  check(
    !suitableForMatching({...original, 'answer': 'Long ' * 100}),
    'Long essays stay out of phone matching rounds',
  );
  final selection = PairSelection();
  selection.tapLeft(0);
  selection.tapRight(1);
  check(
    selection.matches[0] == 1 && selection.activeLeft == null,
    'Tapping left then right forms a pair',
  );
  selection.tapRight(1);
  check(
    selection.matches.isEmpty && selection.activeLeft == 0,
    'Tapping a paired answer unpairs it and selects its question',
  );
  selection.tapRight(0);
  check(selection.matches[0] == 0, 'An unpaired question can be paired again');
  selection.tapLeft(1);
  selection.tapRight(0);
  check(
    !selection.matches.containsKey(0) && selection.matches[1] == 0,
    'Reassignment cannot pair one answer to two questions',
  );
  selection.tapLeft(1);
  check(
    selection.matches.isEmpty && selection.activeLeft == 1,
    'Tapping a paired question unpairs it',
  );
  check(
    scopedQuestions(
          [
            original,
            second,
            {'id': 'legacy', 'subject': 'bio'},
            {'subject': 'math'},
          ],
          'bio',
          '',
        ).single['id'] ==
        'legacy',
    'Older questions remain in Unassigned chapter',
  );
  check(
    scopedQuestions([original, second], 'bio', 'c1').single['id'] == 'q',
    'Chapter scopes exclude other chapters',
  );
  check(
    scopedQuestions([original, second], 'bio', null).length == 2,
    'Subject study includes all chapters',
  );
  final sessions = revisionSessions([
    {
      'session': 's',
      'subject': 'bio',
      'chapter': 'c1',
      'date': '2026-11-19',
      'timestamp': '2026-11-19T10:00:00Z',
      'rating': 0,
    },
    {
      'session': 's',
      'subject': 'bio',
      'chapter': 'c1',
      'date': '2026-11-19',
      'timestamp': '2026-11-19T10:01:00Z',
      'rating': 3,
    },
    {
      'session': 's',
      'subject': 'math',
      'date': '2026-11-19',
      'timestamp': '2026-11-19T10:02:00Z',
      'rating': 2,
    },
    {'subject': 'bio', 'date': '2026-11-18', 'rating': 1},
  ]);
  check(
    sessions.length == 3,
    'History groups attempts into sessions and separates subjects',
  );
  check(sessions.first['subject'] == 'math', 'Sessions are shown newest first');
  check(
    sessions[1]['attempts'].length == 2 && sessions[1]['needsPractice'] == 1,
    'Session summaries count attempts needing practice',
  );
  stdout.writeln('$passed study-content checks passed.');
}
