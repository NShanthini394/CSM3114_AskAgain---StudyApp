import 'package:timezone/data/latest_all.dart' as database;
import 'package:timezone/timezone.dart' as tz;

/// Android may return historical IANA identifiers, including Asia/Kuala_Lumpur.
tz.Location configureDeviceTimeZone(String identifier, Duration deviceOffset) {
  database.initializeTimeZones();
  tz.Location location;
  try {
    location = tz.getLocation(identifier);
  } on tz.LocationNotFoundException {
    // Unknown vendor names use the phone's offset, refreshed on the next launch.
    location = tz.Location('Device local time', [tz.minTime], [0], [
      tz.TimeZone(deviceOffset, isDst: false, abbreviation: 'Local'),
    ]);
  }
  tz.setLocalLocation(location);
  return location;
}
