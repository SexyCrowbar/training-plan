import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  // GTG channel (existing)
  static const _gtgChannelId = 'gtg_reminders';
  static const _gtgChannelName = 'GTG Reminders';
  static const _gtgChannelDesc = 'Hourly reminders to do a Grease-the-Groove set.';
  static const _gtgNotificationId = 1001;

  // Rest timer channel (new)
  static const _restChannelId = 'rest_timer_alerts';
  static const _restChannelName = 'Rest timer alerts';
  static const _restChannelDesc = 'Notifies when your rest timer is up.';
  static const _restNotificationId = 1002;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _plugin.initialize(init);
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _gtgChannelId,
      _gtgChannelName,
      description: _gtgChannelDesc,
      importance: Importance.defaultImportance,
    ));
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _restChannelId,
      _restChannelName,
      description: _restChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
  }

  static Future<bool> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission() ?? true;
    return granted;
  }

  static Future<void> postGtgReminder() async {
    const androidDetails = AndroidNotificationDetails(
      _gtgChannelId,
      _gtgChannelName,
      channelDescription: _gtgChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      _gtgNotificationId,
      'Grease the Groove',
      'Time for a set. Keep it easy — no sweat.',
      details,
    );
  }

  static Future<void> postRestTimerAlert() async {
    const androidDetails = AndroidNotificationDetails(
      _restChannelId,
      _restChannelName,
      channelDescription: _restChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      _restNotificationId,
      'Rest over',
      'Time for your next set.',
      details,
    );
  }
}
