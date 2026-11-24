import 'package:askagain/services/generation_input.dart';
import 'package:askagain/services/generation_quota.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as zones;

void main() {
  setUpAll(zones.initializeTimeZones);
  test(
    'short slides share a request while dense input and output stay bounded',
    () {
      expect(
        plannedGenerationCalls({for (var i = 0; i < 24; i++) i: 'x' * 500}, 5),
        1,
      );
      expect(
        plannedGenerationCalls({for (var i = 0; i < 24; i++) i: 'x' * 4000}, 5),
        4,
      );
      expect(plannedGenerationCalls({1: 'x' * 4000}, 25), 4);
    },
  );

  test('a daily limit in Malaysia follows Pacific midnight including daylight saving', () {
    for (final month in [6, 11]) {
      final now = DateTime.utc(2026, month, 22, 4, 46);
      final pause = GenerationQuotaPause.fromMessage(
        'RequestsPerDayPerProjectPerModel. Retry in 5s',
        now,
      );
      expect(
        pause.until.toUtc(),
        DateTime.utc(2026, month, 22, month == 6 ? 7 : 8),
      );
    }
  });

  test('respects provider delay and does not mislabel an unspecified limit as daily', () {
    final now = DateTime.utc(2026, 11, 22);
    final pause = GenerationQuotaPause.fromMessage(
      'Requests per minute. Please retry in 1m4.2s.',
      now,
    );
    expect(pause.until.difference(now).inSeconds, 65);
    expect(pause.reason, contains('per-minute'));
    expect(
      GenerationQuotaPause.fromMessage('Quota exceeded', now).reason,
      isNot(contains('daily')),
    );
  });
}
