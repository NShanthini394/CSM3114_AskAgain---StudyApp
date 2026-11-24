import 'dart:math' as math;

int nextInterval(int previous, int rating) => switch (rating) {
  0 => 1,
  1 => 2,
  2 => (previous * 2).clamp(4, 90),
  3 => (previous * 3).clamp(10, 180),
  _ => throw ArgumentError.value(rating, 'rating'),
};

int questionLimit(Map<int, String> pages) {
  if (pages.isEmpty) return 0;
  final characters = pages.values.fold(0, (total, page) => total + page.length);
  final pageBound = pages.length == 1
      ? math.max(3, (characters / 180).ceil())
      : pages.length * 3;
  return math.min(
    100,
    math.min(math.max(1, (characters / 65).ceil()), pageBound),
  );
}

const dailyGenerationRequestAllowance = 16;

int estimatedGenerationRequests(int pages, int questions) {
  if (pages <= 0 || questions <= 0) return 0;
  return math.min(
    questions,
    math.max((pages / 6).ceil(), (questions / 8).ceil()),
  );
}

bool withinDailyGenerationAllowance({
  required int usedRequests,
  required int requestedRequests,
  required int requestedPages,
  required int requestedQuestions,
}) {
  return usedRequests >= 0 &&
      requestedRequests >= 0 &&
      requestedPages > 0 &&
      requestedPages <= 80 &&
      requestedQuestions > 0 &&
      requestedQuestions <= 100 &&
      usedRequests + requestedRequests <= dailyGenerationRequestAllowance;
}

bool matchesNumericAnswer(
  String submitted,
  double expected,
  double tolerance,
  String submittedUnit,
  String expectedUnit,
) {
  final actual = double.tryParse(submitted.trim());
  return actual != null &&
      actual.isFinite &&
      tolerance >= 0 &&
      (actual - expected).abs() <= tolerance + 1e-12 &&
      submittedUnit.trim() == expectedUnit.trim();
}
