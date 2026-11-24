import 'dart:convert';
import 'dart:io';

import 'package:askagain/data/subject_styles.dart';
import 'package:askagain/data/heading_case.dart';

void main() {
  void check(bool ok, String name) {
    if (!ok) throw StateError(name);
    stdout.writeln('PASS $name');
  }

  final old = <SubjectRecord>[
    {'id': 'bio', 'kind': 'subject', 'name': 'Biology'},
    {'id': 'maths', 'kind': 'subject', 'name': 'Mathematics'},
    {'id': 'code', 'kind': 'subject', 'name': 'Dart', 'colourIndex': 3},
  ];
  final migrated = missingSubjectStyles(old);
  check(
    migrated.length == 2 &&
        migrated[0]['colourIndex'] == 0 &&
        migrated[1]['colourIndex'] == 1,
    'Upgrade preserves the previous folder colour order',
  );
  check(
    !migrated.any((s) => s['id'] == 'code'),
    'Upgrade keeps existing saved colours',
  );
  check(
    !old.first.containsKey('colourIndex'),
    'Colour preparation does not mutate input records',
  );
  final stored = <String, SubjectRecord>{
    for (final row in [...old, ...migrated]) row['id']: row,
  };
  final renamed = styledSubjectUpdates(stored, [
    {'id': 'maths', 'kind': 'subject', 'name': 'Statistics'},
  ]).single;
  check(
    renamed['colourIndex'] == 1,
    'Renaming without a colour field retains the saved colour',
  );
  final kept = {...stored}..remove('bio');
  check(
    subjectColour(kept['maths']) == 1,
    'Deleting another subject cannot change an existing colour',
  );
  check(
    missingSubjectStyles(kept.values.toList().reversed).isEmpty,
    'Reordering saved subjects does not assign new colours',
  );
  final reopened = (jsonDecode(jsonEncode(kept)) as Map).map(
    (key, value) => MapEntry(key as String, Map<String, dynamic>.from(value)),
  );
  check(
    subjectColour(reopened['code']) == 3,
    'Saved colour survives notebook serialization',
  );
  final added = styledSubjectUpdates(stored, [
    {'id': 'new1', 'kind': 'subject', 'name': 'History'},
    {'id': 'new2', 'kind': 'subject', 'name': 'Physics'},
  ]);
  check(
    added[0]['colourIndex'] == 3 && added[1]['colourIndex'] == 0,
    'Multiple new subjects receive valid cycling palette colours',
  );
  check(
    subjectColour({'colourIndex': 'green'}) == 0 &&
        subjectColour({'colourIndex': -1}) == 0 &&
        subjectColour(null) == 0,
    'Malformed or removed subject colours use a safe fallback',
  );
  final fixed = missingSubjectStyles([
    {'id': 'bad', 'colourIndex': 99},
  ]);
  check(
    fixed.single['colourIndex'] == 0,
    'Upgrade repairs out-of-range colours',
  );
  final question = {
    'id': 'q',
    'subject': 'maths',
    'prompt': 'pH of H2O?',
    'answer': 'pH 7',
  };
  final untouched = styledSubjectUpdates(stored, [question]).single;
  check(
    identical(question, untouched) && untouched['prompt'] == 'pH of H2O?',
    'Subject styling never changes question content or case',
  );
  check(
    headingCase('revision queue') == 'Revision Queue',
    'Section words use title case',
  );
  check(
    headingCase('revise by subject') == 'Revise by Subject',
    'Short linking words remain lowercase',
  );
  check(
    headingCase('the role of a neuron') == 'The Role of a Neuron',
    'Articles follow heading position',
  );
  check(
    headingCase('Welcome to AskAgain with AI and PDF') ==
        'Welcome to AskAgain with AI and PDF',
    'Brand names and acronyms retain their casing',
  );
  check(
    headingCase('') == '' && headingCase('123') == '123',
    'Empty or numeric headings are safe',
  );
}
