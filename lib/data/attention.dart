import 'study_content.dart';

class AttentionGroup {
  const AttentionGroup(this.reason, this.questions);
  final String reason;
  final List<ContentRecord> questions;
}

List<String> attemptedQuestionIds(ContentRecord attempt) {
  final stored = attempt['questionIds'];
  final ids = stored is List
      ? stored.whereType<String>().where((id) => id.isNotEmpty).toSet()
      : <String>{};
  if (ids.isEmpty && attempt['question'] is String) {
    final id = attempt['question'] as String;
    if (id.isNotEmpty) ids.add(id);
  }
  return ids.toList();
}

DateTime _attemptTime(ContentRecord attempt) =>
    DateTime.tryParse(attempt['timestamp']?.toString() ?? '') ??
    DateTime.tryParse(attempt['date']?.toString() ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// One entry per current question, using its latest practice attempt.
/// Recall sessions do not record a difficulty and must not erase one.
List<AttentionGroup> attentionGroups(
  Iterable<ContentRecord> questions,
  Iterable<ContentRecord> attempts,
) {
  final latest = <String, ContentRecord>{};
  for (final attempt in attempts) {
    if (attempt['activity'] == 'recall') continue;
    for (final id in attemptedQuestionIds(attempt)) {
      final previous = latest[id];
      if (previous == null ||
          !_attemptTime(attempt).isBefore(_attemptTime(previous))) {
        latest[id] = attempt;
      }
    }
  }
  final groups = <String, Map<String, ContentRecord>>{};
  for (final question in questions) {
    if (question['approved'] == false || question['rating'] == 3) continue;
    final id = question['id'] as String;
    final reason = (latest[id]?['mistake'] as String? ?? '').trim();
    if (reason.isNotEmpty) (groups[reason] ??= {})[id] = question;
  }
  final result = [
    for (final entry in groups.entries)
      AttentionGroup(
        entry.key,
        entry.value.values.toList()..sort(
          (a, b) => (a['studyPrompt'] ?? a['prompt']).toString().compareTo(
            (b['studyPrompt'] ?? b['prompt']).toString(),
          ),
        ),
      ),
  ];
  result.sort((a, b) {
    final size = b.questions.length.compareTo(a.questions.length);
    return size == 0 ? a.reason.compareTo(b.reason) : size;
  });
  return result;
}
