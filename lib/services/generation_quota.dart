import 'dart:math' as math;

import 'package:timezone/timezone.dart' as tz;

/// A Gemini response may identify one or several exhausted quota dimensions.
class GenerationQuotaPause implements Exception {
  const GenerationQuotaPause(this.reason, this.until);
  final String reason;
  final DateTime until;

  static GenerationQuotaPause fromMessage(String message, DateTime now) {
    final daily = RegExp(
      r'per[ _-]?day|daily',
      caseSensitive: false,
    ).hasMatch(message);
    final minute = RegExp(
      r'per[ _-]?minute',
      caseSensitive: false,
    ).hasMatch(message);
    final hint = RegExp(
      r'(?:retry in\s+|retryDelay["\s:]+)(?:(\d+)h)?(?:(\d+)m)?(\d+(?:\.\d+)?)s',
      caseSensitive: false,
    ).firstMatch(message);
    final seconds = hint == null
        ? 60
        : (int.tryParse(hint[1] ?? '') ?? 0) * 3600 +
              (int.tryParse(hint[2] ?? '') ?? 0) * 60 +
              double.parse(hint[3]!).ceil();
    var until = now.add(Duration(seconds: math.max(1, seconds)));
    if (daily) {
      final pacific = tz.getLocation('America/Los_Angeles');
      final time = tz.TZDateTime.from(now, pacific);
      final reset = tz.TZDateTime(pacific, time.year, time.month, time.day + 1);
      if (reset.isAfter(until) || hint == null) until = reset;
    }
    return GenerationQuotaPause(
      daily
          ? 'Gemini reached the project’s daily limit.'
          : minute
          ? 'Gemini reached a per-minute limit.'
          : 'Gemini limited requests for this project.',
      until,
    );
  }

  @override
  String toString() {
    final stamp = until.toLocal().toString().substring(0, 16);
    return '$reason Try again from $stamp (phone time).';
  }
}
