import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/db/app_database.dart';
import '../data/repositories/settings_repository.dart';
import 'notification_helper.dart';

const int _alarmId = 42001;

class ReminderScheduler {
  static Future<void> scheduleNext({
    required bool enabled,
    required int startHour,
    required int endHour,
  }) async {
    await AndroidAlarmManager.cancel(_alarmId);
    if (!enabled) return;

    final now = DateTime.now();
    final target = _nextFireTime(
      now: now,
      startHour: startHour,
      endHour: endHour,
    );

    await AndroidAlarmManager.oneShotAt(
      target,
      _alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      alarmClock: false,
      allowWhileIdle: true,
    );
  }

  static Future<void> cancel() async {
    await AndroidAlarmManager.cancel(_alarmId);
  }

  static DateTime _nextFireTime({
    required DateTime now,
    required int startHour,
    required int endHour,
  }) {
    // If before startHour → fire at startHour today.
    if (now.hour < startHour) {
      return DateTime(now.year, now.month, now.day, startHour);
    }
    // If after endHour (inclusive) → fire at startHour tomorrow.
    if (now.hour >= endHour) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, startHour);
    }
    // Within window → fire at the top of the next hour.
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    if (nextHour.hour >= endHour) {
      // Next hour would be past the end window; wrap to tomorrow.
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, startHour);
    }
    return nextHour;
  }

  /// Determine which day of the 5-day rotation today is.
  /// Simple calendar-based: dayId = ((daysSinceEpoch) % 5) + 1.
  /// Day 5 is rest day.
  static int currentRotationDayId(DateTime now) {
    final daysSinceEpoch = now.toUtc().difference(DateTime.utc(1970, 1, 1)).inDays;
    return (daysSinceEpoch % 5) + 1;
  }
}

/// Top-level callback required by android_alarm_manager_plus — runs in a
/// background isolate, so it must open its own DB + notification plugin.
@pragma('vm:entry-point')
Future<void> _alarmCallback() async {
  // Open a short-lived DB connection in this isolate.
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'protocol.db'));
  final db = AppDatabase.forTesting(NativeDatabase(file));

  try {
    final settings = SettingsRepository(db);
    final enabled = await settings.getBool(SettingsKeys.remindersEnabled);
    if (!enabled) return;

    final startHour = await settings.getInt(SettingsKeys.startHour) ?? 9;
    final endHour = await settings.getInt(SettingsKeys.endHour) ?? 18;

    final now = DateTime.now();
    final withinWindow = now.hour >= startHour && now.hour < endHour;
    final isRestDay = ReminderScheduler.currentRotationDayId(now) == 5;

    if (withinWindow && !isRestDay) {
      await NotificationHelper.initialize();
      await NotificationHelper.postGtgReminder();
    }

    await ReminderScheduler.scheduleNext(
      enabled: true,
      startHour: startHour,
      endHour: endHour,
    );
  } finally {
    await db.close();
  }
}
