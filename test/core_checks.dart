import 'dart:io';

import 'package:askagain/data/study_rules.dart';

void main() {
  void check(bool ok, String name) {
    if (!ok) throw StateError(name);
    stdout.writeln('PASS $name');
  }

  bool allowed(int used, int requests, int pages, int questions) =>
      withinDailyGenerationAllowance(
        usedRequests: used,
        requestedRequests: requests,
        requestedPages: pages,
        requestedQuestions: questions,
      );
  check(
    estimatedGenerationRequests(68, 75) == 12 &&
        estimatedGenerationRequests(80, 100) == 14 &&
        estimatedGenerationRequests(1, 1) == 1,
    'Request estimate matches the generator batch formula',
  );
  check(
    allowed(2, 14, 80, 100) &&
        !allowed(3, 14, 80, 100) &&
        !allowed(16, 1, 1, 1),
    'Daily planning allowance is based on attempted AI requests',
  );
  check(
    !allowed(0, 1, 81, 1) && !allowed(0, 1, 1, 101) && !allowed(0, 1, 0, 1),
    'Per-document limits',
  );
  check(
    questionLimit({1: 'Hello'}) == 1 &&
        questionLimit({for (var i = 0; i < 80; i++) i: 'x' * 1000}) == 100,
    'Content-based recommendation bounds',
  );
  check(
    nextInterval(20, 0) == 1 &&
        nextInterval(20, 3) == 60 &&
        nextInterval(100, 3) == 180,
    'Recall schedule responds to rating and caps long intervals',
  );
  check(
    matchesNumericAnswer('78.55', 78.54, .01, 'cm²', 'cm²') &&
        !matchesNumericAnswer('78.54', 78.54, .01, 'cm', 'cm²') &&
        !matchesNumericAnswer('NaN', 78.54, .01, 'cm²', 'cm²'),
    'Numeric answers enforce rounding and units',
  );
}
