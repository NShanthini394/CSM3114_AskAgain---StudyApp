import 'dart:io';

import 'package:askagain/services/device_time_zone.dart';
import 'package:timezone/data/latest.dart' as reduced;
import 'package:timezone/timezone.dart' as tz;

void main() {
  void check(bool value, String label) {
    if (!value) throw StateError(label);
    stdout.writeln('PASS $label');
  }

  reduced.initializeTimeZones();
  var originalFailure = false;
  try {
    tz.getLocation('Asia/Kuala_Lumpur');
  } on tz.LocationNotFoundException {
    originalFailure = true;
  }
  check(
    originalFailure,
    'Reproduced the reported crash with the previous reduced database',
  );
  final malaysia = configureDeviceTimeZone(
    'Asia/Kuala_Lumpur',
    const Duration(hours: 8),
  );
  final reminder = tz.TZDateTime(malaysia, 2026, 11, 19, 18);
  check(
    reminder.timeZoneOffset == const Duration(hours: 8),
    'Kuala Lumpur resolves to UTC+8',
  );
  check(
    reminder.isAtSameMomentAs(DateTime.utc(2026, 11, 19, 10)),
    '6 pm reminder preserves Malaysian wall-clock time',
  );
  final london = configureDeviceTimeZone('Europe/London', Duration.zero);
  check(
    tz.TZDateTime(london, 2026, 7, 1).timeZoneOffset ==
            const Duration(hours: 1) &&
        tz.TZDateTime(london, 2026, 12, 1).timeZoneOffset == Duration.zero,
    'Known zones preserve seasonal clock changes',
  );
  final fallback = configureDeviceTimeZone(
    'Vendor/Unknown',
    const Duration(hours: 5, minutes: 30),
  );
  check(
    tz.TZDateTime(
      fallback,
      2026,
      11,
      19,
      18,
    ).isAtSameMomentAs(DateTime.utc(2026, 11, 19, 12, 30)),
    'Unknown device name uses the phone offset without blocking startup',
  );
  final negative = configureDeviceTimeZone('', const Duration(hours: -4));
  check(
    tz.TZDateTime(negative, 2026, 11, 19).timeZoneOffset ==
        const Duration(hours: -4),
    'Missing identifier supports negative device offsets',
  );
}
