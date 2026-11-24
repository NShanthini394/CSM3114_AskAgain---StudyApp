import 'dart:io';

import 'package:askagain/data/review_schedule.dart';

void main() {
  var count = 0;
  void check(bool ok, String name) {
    if (!ok) throw StateError(name);
    count++;
    stdout.writeln('PASS $name');
  }

  final source = <String, dynamic>{
    'id': 'q',
    'prompt': 'Original question',
    'answer': 'Original answer',
    'chapter': 'c1',
  };
  final first = scheduledReview(
    source,
    2,
    DateTime(2026, 11, 19),
    activity: 'recall',
  );
  check(first['rating'] == 2, 'One fully remembered card becomes understood');
  final repeat = scheduledReview(
    first,
    2,
    DateTime(2026, 11, 19, 20),
    activity: 'recall',
  );
  check(
    (repeat['recallSuccessDays'] as List).length == 1 && repeat['rating'] == 2,
    'Same-day repetitions cannot inflate mastery',
  );
  final second = scheduledReview(
    first,
    2,
    DateTime(2026, 11, 23),
    activity: 'recall',
  );
  final third = scheduledReview(
    second,
    2,
    DateTime(2026, 12, 1),
    activity: 'recall',
  );
  check(
    third['rating'] == 3,
    'Fully remembered reviews on three separate dates earn mastery',
  );
  final forgotten = scheduledReview(
    third,
    0,
    DateTime(2026, 12, 10),
    activity: 'recall',
  );
  check(
    forgotten['rating'] == 0 &&
        (forgotten['recallSuccessDays'] as List).isEmpty &&
        forgotten['interval'] == 1,
    'Forgotten recall resets the success history and schedules tomorrow',
  );
  check(
    third['prompt'] == source['prompt'] &&
        third['answer'] == source['answer'] &&
        third['chapter'] == 'c1',
    'Scheduling preserves question content and chapter',
  );
  check(
    scheduledReview(third, 3, DateTime(2026, 12, 10))['rating'] == 3,
    'Existing practice mastery ratings remain supported',
  );
  stdout.writeln('$count review-schedule checks passed.');
}
