import 'dart:math' as math;

import '../data/answer_formats.dart';
import '../data/notebook.dart';

String normalizedQuestion(String text) =>
    text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Accepts only a question that can be traced to an exact source passage.
/// Generation never marks a draft as approved for revision.
StudyRecord? buildGeneratedQuestion(
  Object? draft,
  Map<int, String> sourcePages,
  Set<String> seen,
  StudyRecord settings,
  String documentId,
  int index,
) {
  if (draft is! Map) return null;
  final row = StudyRecord.from(draft);
  final page = int.tryParse(row['page']?.toString() ?? '');
  final quote = row['evidence'];
  final prompt = row['prompt'];
  final answer = row['answer'];
  if (prompt is! String ||
      prompt.trim().isEmpty ||
      answer is! String ||
      answer.trim().isEmpty ||
      quote is! String ||
      quote.trim().isEmpty ||
      !normalizedQuestion(sourcePages[page] ?? '')
          .contains(normalizedQuestion(quote)) ||
      seen.contains(normalizedQuestion(prompt))) {
    return null;
  }

  final format = row['responseFormat'];
  final responseFormat = responseFormats.contains(format)
      ? format as String
      : 'Written answer';
  final structured = <String, dynamic>{
    'prompt': prompt,
    'responseFormat': responseFormat,
    if (format == 'Fill in the blanks') 'blanks': row['blanks'],
    if (format == 'Matching') 'pairs': row['pairs'],
    'numeric': row['numeric'],
    'tolerance': row['tolerance'] ?? 0,
  };
  if (validateResponse(structured) != null) return null;

  return {
    'responseFormat': responseFormat,
    if (format == 'Fill in the blanks') 'blanks': row['blanks'],
    if (format == 'Matching') 'pairs': row['pairs'],
    'type': row['type'] is String && (row['type'] as String).trim().isNotEmpty
        ? row['type']
        : 'Explanation',
    'prompt': prompt.trim(),
    'answer': answer.trim(),
    'page': page,
    'evidence': quote.trim(),
    'topic': row['topic'] is String ? row['topic'] : 'General',
    'difficulty': ['Easy', 'Medium', 'Hard'].contains(row['difficulty'])
        ? row['difficulty']
        : 'Medium',
    'numeric': double.tryParse(row['numeric']?.toString() ?? ''),
    'tolerance': math.max(
      0,
      double.tryParse(row['tolerance']?.toString() ?? '') ?? 0,
    ),
    'unit': row['unit'] is String ? row['unit'] : '',
    'id': '$documentId-$index',
    'kind': 'question',
    'mode': ['Calculation', 'Statistics', 'Programming'].contains(row['mode'])
        ? row['mode']
        : 'Theory',
    'document': documentId,
    'subject': settings['subject'],
    'chapter': settings['chapter'] ?? '',
    'suggestedChapter': row['chapterName'] is String ? row['chapterName'] : '',
    'approved': false,
    'due': today(),
  };
}
