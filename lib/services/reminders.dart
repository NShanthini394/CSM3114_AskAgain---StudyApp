import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/widgets.dart';

import '../data/notebook.dart';
import 'device_time_zone.dart';

class Reminders {
  static final plugin = FlutterLocalNotificationsPlugin();
  static Future<void> init(VoidCallback onTap) async {
    String identifier;
    try {
      identifier = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      identifier = '';
    }
    configureDeviceTimeZone(identifier, DateTime.now().timeZoneOffset);
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_review'),
      ),
      onDidReceiveNotificationResponse: (_) => onTap(),
    );
    if ((await plugin.getNotificationAppLaunchDetails())
            ?.didNotificationLaunchApp ==
        true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onTap());
    }
  }

  static Future<bool> permit() async =>
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      false;
  static Future<void> refresh(Notebook b) async {
    await plugin.cancelAll();
    if (!b.active || b.profile['remind'] != true || b.questions.isEmpty) return;
    final now = tz.TZDateTime.now(tz.local);
    final preferred = b.profile['minutes'] as int? ?? 1080;
    final minutes =
        b.profile['quiet'] == true && (preferred >= 1320 || preferred < 420)
        ? 420
        : preferred;
    final dueDates =
        b.questions.map((q) => q['due'] as String? ?? today()).toList()..sort();
    final firstDue = DateTime.tryParse(dueDates.first) ?? now;
    final repeatStart = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 14,
      minutes ~/ 60,
      minutes % 60,
    );
    final firstReminder = tz.TZDateTime(
      tz.local,
      firstDue.year,
      firstDue.month,
      firstDue.day,
      minutes ~/ 60,
      minutes % 60,
    );
    for (int day = 0; day < 14; day++) {
      final when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!when.isAfter(now)) continue;
      final key = when.toIso8601String().split('T').first;
      final count = b.questions
          .where((q) => (q['due'] as String? ?? '').compareTo(key) <= 0)
          .length;
      if (count == 0) continue;
      await plugin.zonedSchedule(
        id: day + 1,
        title: 'Time to revise',
        body: '$count questions due. Tap to open your revision queue.',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('revision', 'Revision reminders'),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    await plugin.zonedSchedule(
      id: 15,
      title: 'Time to revise',
      body: 'Open your due questions in AskAgain.',
      scheduledDate: firstReminder.isAfter(repeatStart)
          ? firstReminder
          : repeatStart,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('revision', 'Revision reminders'),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
