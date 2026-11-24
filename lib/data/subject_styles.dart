typedef SubjectRecord = Map<String, dynamic>;

bool validSubjectColour(dynamic value) =>
    value is int && value >= 0 && value < 4;

int subjectColour(SubjectRecord? subject) =>
    validSubjectColour(subject?['colourIndex'])
    ? subject!['colourIndex'] as int
    : 0;

/// Assign the former list colours once to existing notebooks.
List<SubjectRecord> missingSubjectStyles(Iterable<SubjectRecord> subjects) => [
  for (final item in subjects.indexed)
    if (!validSubjectColour(item.$2['colourIndex']))
      {...item.$2, 'colourIndex': item.$1 % 4},
];

List<SubjectRecord> styledSubjectUpdates(
  Map<String, SubjectRecord> stored,
  List<SubjectRecord> updates,
) {
  var next = stored.values.where((row) => row['kind'] == 'subject').length;
  final assigned = <String, int>{};
  return [
    for (final row in updates)
      if (row['kind'] != 'subject')
        row
      else
        {
          ...row,
          'colourIndex': validSubjectColour(row['colourIndex'])
              ? row['colourIndex']
              : assigned.putIfAbsent(row['id'] as String, () {
                  final previous = stored[row['id']];
                  return validSubjectColour(previous?['colourIndex'])
                      ? subjectColour(previous)
                      : next++ % 4;
                }),
        },
  ];
}
