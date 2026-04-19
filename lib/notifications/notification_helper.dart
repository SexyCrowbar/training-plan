import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static const _channelId = 'gtg_reminders';
  static const _channelName = 'GTG Reminders';
  static const _channelDesc = 'Hourly reminders to do a Grease-the-Groove set.';
  static const _gtgNotificationId = 1001;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _plugin.initialize(init);
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.defaultImportance,
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
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
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
}
