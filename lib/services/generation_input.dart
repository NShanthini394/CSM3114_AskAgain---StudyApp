import 'dart:math' as math;

/// Plan by bounded source text and output count. Short slide pages can share
/// one call without increasing the existing per-request text budget.
int plannedGenerationCalls(Map<int, String> pages, int questions) {
  if (pages.isEmpty || questions <= 0) return 0;
  final characters = pages.values.fold<int>(
    0,
    (sum, page) => sum + math.min(4000, page.length),
  );
  return math.min(
    questions,
    math.max((characters / 24000).ceil(), (questions / 8).ceil()),
  );
}

/// Keeps a single Gemini request small even when PDF extraction returns a
/// very dense page. Short pages are sent without changes.
Map<int, String> prepareGenerationPages(Map<int, String> pages) {
  if (pages.isEmpty) return {};
  final perPage = math.min(4000, 24000 ~/ pages.length);
  return pages.map((number, text) => MapEntry(number, _excerpt(text, perPage)));
}

String _excerpt(String text, int limit) {
  if (text.length <= limit) return text;
  final width = (limit - 6) ~/ 3;
  if (width <= 0) return text.substring(0, limit);
  final middle = (text.length - width) ~/ 2;
  return '${text.substring(0, width)}\n…\n'
      '${text.substring(middle, middle + width)}\n…\n'
      '${text.substring(text.length - width)}';
}

bool isTemporaryGenerationFailure(Object error) {
  final message = error.toString();
  return message.contains('TimeoutException') ||
      RegExp(r'Server Error \[(502|503|504)\]').hasMatch(message) ||
      isGenerationOverloaded(error);
}

/// Retry only the explicit provider overload, not every internal/server error.
bool isGenerationOverloaded(Object error) {
  final message = error.toString();
  return RegExp(r'Server Error \[(500|503)\]').hasMatch(message) &&
      RegExp(r'high demand|overloaded', caseSensitive: false).hasMatch(message);
}

String generationFailureMessage(Object error) {
  if (isGenerationOverloaded(error)) {
    return 'Google’s AI service is busy, even after one automatic retry. '
        'This is a server-capacity problem, not a PDF or daily-quota error. '
        'Completed batches are saved. Close this popup and retry later; '
        'there is no guaranteed recovery time.';
  }
  if (isTemporaryGenerationFailure(error)) {
    return 'Gemini could not finish this batch after one automatic retry. '
        'Completed batches are saved. Tap Retry later to continue, '
        'or select a shorter page range for a new document.';
  }
  return error.toString().replaceFirst(
    RegExp(r'^Bad state: |^Exception: '),
    '',
  );
}
