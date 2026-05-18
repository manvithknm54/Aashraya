import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: android,
    );

    await _plugin.initialize(settings);

    await _requestPermission();

    _initialized = true;
  }

  static Future<void> _requestPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin androidPlugin =
          _plugin.resolvePlatformSpecificImplementation()!;
      await androidPlugin.requestNotificationsPermission();
    } catch (_) {}
  }

  // Schedule task reminder exactly at reminder time
  static Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String emoji,
    required DateTime dueTime,
  }) async {
    await init();

    if (dueTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      '🏠 Aashraya — Task Reminder',
      '$emoji $title — Time to do this now!',
      tz.TZDateTime.from(dueTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminders for daily tasks',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Show immediate notification
  static Future<void> showNow({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await init();

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'aashraya_alerts',
          'Aashraya Alerts',
          channelDescription: 'Important alerts',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  // Schedule daily 6 PM report reminder
  static Future<void> scheduleDailyReportReminder() async {
    await init();

    await _plugin.cancel(888);

    final now = DateTime.now();

    var evening = DateTime(now.year, now.month, now.day, 18, 0, 0);

    if (evening.isBefore(now)) {
      evening = evening.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      888,
      '📊 Daily Report Ready',
      'Time to generate today\'s elder health reports!',
      tz.TZDateTime.from(evening, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reports',
          'Daily Reports',
          channelDescription: 'Daily report reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule daily 8 PM evening report reminder
  static Future<void> scheduleEveningReport() async {
    await init();

    await _plugin.cancel(889);

    final now = DateTime.now();

    var evening = DateTime(now.year, now.month, now.day, 20, 0, 0);

    if (evening.isBefore(now)) {
      evening = evening.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      889,
      '📊 Aashraya Daily Report Ready',
      'Check how your elder did today. Generate the daily report now.',
      tz.TZDateTime.from(evening, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reports',
          'Daily Reports',
          channelDescription: 'Evening daily report reminder',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule midnight reset notification
  static Future<void> scheduleMidnightReset() async {
    await init();

    await _plugin.cancel(777);

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);

    await _plugin.zonedSchedule(
      777,
      '🏠 Aashraya',
      'New day started! Your tasks have been refreshed.',
      tz.TZDateTime.from(midnight, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'midnight_reset',
          'Daily Reset',
          channelDescription: 'Midnight task reset',
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // Cancel one notification
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}