import 'dart:io';

import 'package:askagain/services/generation_input.dart';

void main() {
  void check(bool condition, String name) {
    if (!condition) throw StateError(name);
    stdout.writeln('PASS $name');
  }

  final short = {2: 'A short page with a precise source quote.'};
  check(
    prepareGenerationPages(short)[2] == short[2],
    'Short source pages remain intact',
  );

  final dense = 'A' * 6000 + 'B' * 6000 + 'C' * 6000;
  final prepared = prepareGenerationPages({
    for (var i = 1; i <= 6; i++) i: dense,
  });
  check(
    prepared.length == 6 &&
        prepared.values.every(
          (page) =>
              page.length <= 4000 &&
              page.startsWith('A') &&
              page.contains('B') &&
              page.endsWith('C'),
        ),
    'Dense pages stay within the request budget and cover their full span',
  );
  check(
    prepared.values.fold(0, (sum, page) => sum + page.length) <= 24000,
    'A batch has a bounded text payload',
  );
  check(
    isTemporaryGenerationFailure(
          'FirebaseAIException: Server Error [503]: unavailable',
        ) &&
        isTemporaryGenerationFailure('TimeoutException after 0:03:00') &&
        !isTemporaryGenerationFailure('Quota exceeded for free tier') &&
        !isTemporaryGenerationFailure('Server Error [429]'),
    'Only transient failures receive an automatic retry',
  );
}
