const responseFormats = [
  'Written answer',
  'Numerical answer',
  'Code answer',
  'Fill in the blanks',
  'Matching',
];

String responseFormat(Map<String, dynamic> question) {
  final stored = question['responseFormat'];
  if (responseFormats.contains(stored)) return stored as String;
  if (question['mode'] == 'Programming') return 'Code answer';
  if (question['numeric'] != null) return 'Numerical answer';
  return 'Written answer';
}

String normaliseAnswer(String answer) =>
    answer.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

List<List<String>> blankAnswers(String text) => text
    .trim()
    .split('\n')
    .map(
      (line) => line
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    )
    .toList();
List<Map<String, String>> matchingPairs(String text) =>
    text.trim().split('\n').map((line) {
      final split = line.indexOf('=');
      return split < 0
          ? <String, String>{}
          : {
              'left': line.substring(0, split).trim(),
              'right': line.substring(split + 1).trim(),
            };
    }).toList();

String? validateResponse(Map<String, dynamic> q) {
  switch (responseFormat(q)) {
    case 'Fill in the blanks':
      final count = RegExp(r'_{3,}')
          .allMatches(q['prompt']?.toString() ?? '')
          .length;
      final groups = q['blanks'];
      if (count == 0) return 'Use ___ for each blank in the question.';
      if (groups is! List || groups.length != count) {
        return 'Enter one answer line for each blank.';
      }
      for (final group in groups) {
        if (group is! List ||
            group.isEmpty ||
            group.any((v) => v is! String || v.trim().isEmpty)) {
          return 'Every blank needs at least one accepted answer.';
        }
      }
    case 'Matching':
      final pairs = q['pairs'];
      if (pairs is! List || pairs.length < 2 || pairs.length > 10) {
        return 'Enter between 2 and 10 matching pairs.';
      }
      final left = <String>{}, right = <String>{};
      for (final pair in pairs) {
        if (pair is! Map ||
            pair['left'] is! String ||
            pair['right'] is! String) {
          return 'Each line must use item = answer.';
        }
        final a = normaliseAnswer(pair['left']),
            b = normaliseAnswer(pair['right']);
        if (a.isEmpty || b.isEmpty || !left.add(a) || !right.add(b)) {
          return 'Use distinct, non-empty items and answers.';
        }
      }
    case 'Numerical answer':
      final target = double.tryParse(q['numeric']?.toString() ?? '');
      if (target == null || !target.isFinite) {
        return 'Enter a finite expected numerical value.';
      }
      final tolerance = double.tryParse(q['tolerance']?.toString() ?? '0');
      if (tolerance == null || !tolerance.isFinite || tolerance < 0) {
        return 'Enter a non-negative tolerance.';
      }
  }
  return null;
}

int scoreBlanks(List<dynamic> groups, List<String> responses) {
  var score = 0;
  for (var i = 0; i < groups.length; i++) {
    if (i < responses.length &&
        (groups[i] as List).any(
          (a) => normaliseAnswer(a.toString()) == normaliseAnswer(responses[i]),
        )) {
      score++;
    }
  }
  return score;
}

int scoreMatching(List<dynamic> pairs, Map<int, int> selected) =>
    List.generate(pairs.length, (i) => i).where((i) => selected[i] == i).length;
