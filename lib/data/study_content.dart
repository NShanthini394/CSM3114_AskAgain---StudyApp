typedef ContentRecord = Map<String, dynamic>;

List<ContentRecord> dueQuestions(
  Iterable<ContentRecord> questions,
  String day,
) => questions
    .where((q) => (q['due'] as String? ?? '').compareTo(day) <= 0)
    .toList();

List<ContentRecord> scopedQuestions(
  Iterable<ContentRecord> questions,
  String? subject,
  String? chapter, {
  Set<String>? questionIds,
}) => questions
    .where(
      (q) =>
          (subject == null || q['subject'] == subject) &&
          (chapter == null || (q['chapter'] ?? '') == chapter) &&
          (questionIds == null || questionIds.contains(q['id'])),
    )
    .toList();

List<RegExpMatch> answerWords(String text) =>
    RegExp(r"[A-Za-z0-9\u00c0-\uffff]+(?:['’-][A-Za-z0-9\u00c0-\uffff]+)*")
        .allMatches(text)
        .toList();

const _commonWords = {
  'a',
  'an',
  'the',
  'of',
  'to',
  'and',
  'or',
  'is',
  'are',
  'was',
  'were',
  'be',
  'in',
  'on',
  'for',
  'with',
  'it',
  'this',
  'that',
  'as',
  'by',
  'at',
};
Set<int> suggestedBlanks(String text) {
  final words = answerWords(text);
  final candidates = List.generate(words.length, (i) => i)
      .where(
        (i) =>
            words[i].group(0)!.length >= 3 &&
            !_commonWords.contains(words[i].group(0)!.toLowerCase()),
      )
      .toList();
  candidates.sort(
    (a, b) => words[b].group(0)!.length.compareTo(words[a].group(0)!.length),
  );
  return candidates.isEmpty
      ? (words.isEmpty ? <int>{} : <int>{0})
      : candidates.take(2).toSet();
}

ContentRecord makeBlankExercise(ContentRecord question, Set<int> selected) {
  final text = question['answer'] as String;
  final words = answerWords(text);
  if (selected.isEmpty || selected.any((i) => i < 0 || i >= words.length)) {
    throw ArgumentError('Choose at least one word.');
  }
  final indices = selected.toList()..sort();
  var cursor = 0;
  final prompt = StringBuffer();
  final blanks = <List<String>>[];
  for (final i in indices) {
    final word = words[i];
    prompt.write(text.substring(cursor, word.start));
    prompt.write('___');
    cursor = word.end;
    blanks.add([word.group(0)!]);
  }
  prompt.write(text.substring(cursor));
  return {
    ...question,
    'prompt': prompt.toString(),
    'responseFormat': 'Fill in the blanks',
    'blanks': blanks,
    '_derived': true,
  };
}

bool suitableForMatching(ContentRecord q) =>
    (q['prompt'] as String? ?? '').trim().isNotEmpty &&
    (q['prompt'] as String).length <= 180 &&
    (q['answer'] as String? ?? '').trim().isNotEmpty &&
    (q['answer'] as String).length <= 220 &&
    q['mode'] != 'Programming' &&
    q['numeric'] == null;
ContentRecord makeMatchingExercise(List<ContentRecord> questions) {
  if (questions.length < 2 || questions.length > 6) {
    throw ArgumentError('Select 2 to 6 pairs.');
  }
  final prompts = <String>{}, answers = <String>{};
  for (final q in questions) {
    if (!suitableForMatching(q) ||
        !prompts.add(q['prompt'].trim().toLowerCase()) ||
        !answers.add(q['answer'].trim().toLowerCase())) {
      throw ArgumentError('Choose distinct short questions and answers.');
    }
  }
  return {
    ...questions.first,
    'chapter': questions.map((q) => q['chapter'] ?? '').toSet().length == 1
        ? questions.first['chapter'] ?? ''
        : '',
    'prompt': 'Match each question with its answer.',
    'responseFormat': 'Matching',
    'pairs': [
      for (final q in questions) {'left': q['prompt'], 'right': q['answer']},
    ],
    'answer': questions
        .map((q) => '${q['prompt']}\n${q['answer']}')
        .join('\n\n'),
    '_sourceIds': questions.map((q) => q['id']).toList(),
    '_derived': true,
  };
}

class PairSelection {
  final Map<int, int> matches = {};
  int? activeLeft;
  void tapLeft(int index) {
    if (matches.remove(index) != null) {
      activeLeft = index;
      return;
    }
    activeLeft = activeLeft == index ? null : index;
  }

  void tapRight(int index) {
    final left = activeLeft;
    if (left != null) {
      matches.removeWhere((key, value) => value == index);
      matches[left] = index;
      activeLeft = null;
    } else {
      final owners = matches.keys
          .where((key) => matches[key] == index)
          .toList();
      if (owners.isNotEmpty) {
        matches.remove(owners.first);
        activeLeft = owners.first;
      }
    }
  }
}

List<ContentRecord> revisionSessions(Iterable<ContentRecord> attempts) {
  final grouped = <String, List<ContentRecord>>{};
  for (final a in attempts) {
    final run = a['session'] as String? ?? 'legacy-${a['date']}';
    final key = '$run-${a['subject']}-${a['chapter'] ?? ''}';
    (grouped[key] ??= []).add(a);
  }
  final sessions = <ContentRecord>[];
  for (final group in grouped.entries) {
    final entries = group.value
      ..sort(
        (a, b) => (b['timestamp'] as String? ?? b['date'] as String).compareTo(
          a['timestamp'] as String? ?? a['date'] as String,
        ),
      );
    sessions.add({
      'id': group.key,
      'subject': entries.first['subject'],
      'chapter': entries.first['chapter'],
      'timestamp': entries.first['timestamp'] ?? entries.first['date'],
      'attempts': entries,
      'needsPractice': entries.where((a) => (a['rating'] ?? 0) < 2).length,
    });
  }
  sessions.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp']));
  return sessions;
}
