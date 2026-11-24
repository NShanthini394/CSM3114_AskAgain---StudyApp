import 'dart:math';

import 'answer_formats.dart';
import 'study_content.dart';

class PracticePlan {
  const PracticePlan(
    this.questions,
    this.included,
    this.total, {
    this.message = '',
  });
  final List<ContentRecord> questions;
  final int included, total;
  final String message;
}

List<ContentRecord> shuffledContent(
  List<ContentRecord> source, {
  Random? random,
  List<String>? previous,
}) {
  final result = List<ContentRecord>.of(source)..shuffle(random ?? Random());
  final reference = previous ?? source.map((q) => q['id'].toString()).toList();
  if (result.length > 1 &&
      result.length == reference.length &&
      List.generate(
        result.length,
        (i) => result[i]['id'].toString() == reference[i],
      ).every((same) => same)) {
    result.add(result.removeAt(0));
  }
  return result;
}

ContentRecord writtenQuestion(ContentRecord q) {
  final format = responseFormat(q);
  return {
    ...q,
    'prompt': q['studyPrompt'] ?? q['prompt'],
    'responseFormat': format == 'Code answer' || format == 'Numerical answer'
        ? format
        : 'Written answer',
  };
}

PracticePlan buildPracticePlan(
  List<ContentRecord> source,
  String mode, {
  Random? random,
  List<String>? previous,
}) {
  if (mode == 'Written / problem solving') {
    return PracticePlan(
      shuffledContent(
        source,
        random: random,
        previous: previous,
      ).map(writtenQuestion).toList(),
      source.length,
      source.length,
    );
  }
  if (mode == 'Fill in the blanks') {
    final eligible = source
        .where(
          (q) =>
              q['mode'] != 'Programming' &&
              q['numeric'] == null &&
              (q['answer'] as String).length <= 1500 &&
              answerWords(q['answer']).length >= 2,
        )
        .toList();
    return PracticePlan(
      shuffledContent(
        eligible,
        random: random,
        previous: previous,
      ).map((q) => makeBlankExercise(q, suggestedBlanks(q['answer']))).toList(),
      eligible.length,
      source.length,
      message: eligible.length == source.length ? '' : 'Long answers, code and numerical problems stay available in written practice.',
    );
  }
  final prompts = <String>{}, answers = <String>{};
  final eligible = <ContentRecord>[];
  for (final q in source) {
    final canonical = {...q, 'prompt': q['studyPrompt'] ?? q['prompt']};
    if (!suitableForMatching(canonical)) continue;
    final prompt = canonical['prompt'].trim().toLowerCase() as String;
    final answer = canonical['answer'].trim().toLowerCase() as String;
    if (prompts.contains(prompt) || answers.contains(answer)) continue;
    prompts.add(prompt);
    answers.add(answer);
    eligible.add(canonical);
  }
  if (eligible.length < 2) {
    return PracticePlan(
      [],
      0,
      source.length,
      message: 'Matching needs at least two distinct short questions and answers. Try written practice.',
    );
  }
  final shuffled = shuffledContent(
    eligible,
    random: random,
    previous: previous,
  );
  final rounds = <ContentRecord>[];
  var cursor = 0;
  while (cursor < eligible.length) {
    final remaining = eligible.length - cursor;
    final size = remaining == 5 ? 3 : min(4, remaining);
    rounds.add(makeMatchingExercise(shuffled.sublist(cursor, cursor + size)));
    cursor += size;
  }
  return PracticePlan(
    rounds,
    eligible.length,
    source.length,
    message: eligible.length == source.length ? '' : 'Long, numerical, code or duplicate items stay available in written practice.',
  );
}

int recallRating(int choice) => switch (choice) {
  0 => 2,
  1 => 1,
  2 => 0,
  _ => throw ArgumentError.value(choice, 'choice'),
};
double recallCompletion(int completed, int total) =>
    total <= 0 ? 0 : (completed / total).clamp(0.0, 1.0);
