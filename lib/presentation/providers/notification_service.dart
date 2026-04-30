import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          await OpenFilex.open(payload);
        }
      },
    );

    // Initialize Timezones
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Request permissions and create channels FIRST
    if (Platform.isAndroid) {
      const AndroidNotificationChannel exportChannel = AndroidNotificationChannel(
        'finance_export_channel',
        'Financial Exports',
        description: 'Notifications for financial data exports',
        importance: Importance.high,
      );

      const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        'daily_reminders_channel',
        'Daily Reminders',
        description: 'Scheduled reminders to log daily transactions',
        importance: Importance.high,
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.createNotificationChannel(exportChannel);
      await androidImplementation?.createNotificationChannel(reminderChannel);
      
      // Request permission for Android 13+
      await androidImplementation?.requestNotificationsPermission();
      // Required for exact alarms on Android 12+
      await androidImplementation?.requestExactAlarmsPermission();
    }

    // Schedule Daily Reminders AFTER permissions are requested
    await scheduleDailyReminders();
  }

  Future<void> showDownloadNotification(String title, String body, {String? payload}) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'finance_export_channel',
      'Financial Exports',
      channelDescription: 'Notifications for financial data exports',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleDailyReminders() async {
    // Schedule 4 notifications
    await _scheduleDailyNotification(
      101, 
      "Good Morning! ☀️", 
      "Time to log your breakfast expenses and start your day.", 
      8, 0,
    );
    await _scheduleDailyNotification(
      102, 
      "Lunch Time 🍽️", 
      "Don't forget to record your meal and any midday costs.", 
      13, 0,
    );
    await _scheduleDailyNotification(
      103, 
      "Evening Check-in 🌆", 
      "Time to log those afternoon coffee or travel expenses.", 
      18, 0,
    );
    await _scheduleDailyNotification(
      104, 
      "Nightly Review 🌙", 
      "Complete your daily logging. How did your budget go today?", 
      21, 0,
    );
  }

  Future<void> _scheduleDailyNotification(
      int id, String title, String body, int hour, int minute) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders_channel',
            'Daily Reminders',
            channelDescription: 'Scheduled reminders to log daily transactions',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Fallback to non-exact scheduling if exact alarms are not permitted
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders_channel',
            'Daily Reminders',
            channelDescription: 'Scheduled reminders to log daily transactions',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
