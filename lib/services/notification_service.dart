import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Bildirim servisini ve zaman dilimi ayarlarını başlatma
  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      final dynamic rawTimeZone = await FlutterTimezone.getLocalTimezone();
      print('DEBUG: Raw Detected Timezone: $rawTimeZone');

      String timeZoneName = rawTimeZone.toString();

      if (timeZoneName.startsWith('TimezoneInfo(')) {
        final match = RegExp(
          r'TimezoneInfo\(([^,]+),',
        ).firstMatch(timeZoneName);
        if (match != null) {
          timeZoneName = match.group(1) ?? 'UTC';
          print('DEBUG: Parsed Timezone: $timeZoneName');
        }
      }

      if (timeZoneName == 'GMT') {
        timeZoneName = 'Europe/Istanbul';
        print('DEBUG: GMT detected, using Europe/Istanbul instead');
      }

      try {
        final location = tz.getLocation(timeZoneName);
        tz.setLocalLocation(location);
        print('DEBUG: Successfully set timezone to: $timeZoneName');
      } catch (e) {
        print(
          'DEBUG: Failed to set timezone "$timeZoneName", trying Europe/Istanbul...',
        );
        try {
          tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
          print('DEBUG: Set timezone to Europe/Istanbul');
        } catch (_) {
          print('DEBUG: Falling back to UTC');
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      }
    } catch (e) {
      print('DEBUG: Error initializing timezone: $e');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        print('DEBUG: Notification Tapped: ${details.payload}');
      },
    );
  }

  // Gerekli bildirim izinlerini isteme
  Future<void> requestPermissions() async {
    print('DEBUG: Requesting Permissions...');

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool? notificationsGranted = await androidImplementation
        ?.requestNotificationsPermission();
    print(
      'DEBUG: Android Notifications Permission Granted: $notificationsGranted',
    );

    await androidImplementation?.requestExactAlarmsPermission();
    print('DEBUG: Requested Exact Alarms Permission');
  }

  // Anlık bildirim gösterme
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    print('DEBUG: Showing Instant Notification');

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'workout_reminders_v2',
        'Workout Reminders',
        channelDescription: 'Daily reminders to workout',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  // Günlük tekrarlı bildirim planlama
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    print('DEBUG: Scheduling Notification for $time');

    final now = tz.TZDateTime.now(tz.local);
    print('DEBUG: Valid Now (Local): $now');

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      print('DEBUG: Time has passed for today, scheduling for tomorrow.');
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('DEBUG: Scheduled Date: $scheduledDate');

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'workout_reminders_v2',
        'Workout Reminders',
        channelDescription: 'Daily reminders to workout',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print('DEBUG: Successfully scheduled EXACT notification.');
    } catch (e) {
      print('DEBUG: Exact alarm failed ($e), falling back to INEXACT.');
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        print('DEBUG: Successfully scheduled INEXACT notification.');
      } catch (e2) {
        print('DEBUG: Failed to schedule INEXACT notification: $e2');
      }
    }
  }

  // Streak hatırlatıcısını planlama
  Future<void> scheduleStreakReminder() async {
    await scheduleDailyNotification(
      id: 0,
      title: '⚠️ Streak\'in bitmek üzere!',
      body: 'Giriş yaparak streak\'ini koru ve motivasyonunu sürdür! 🔥',
      time: const TimeOfDay(hour: 18, minute: 0),
    );
  }

  // Haftalık tekrarlı bildirim planlama
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1 = Pazartesi, 7 = Pazar
    required TimeOfDay time,
  }) async {
    print(
      'DEBUG: Scheduling Weekly Notification for weekday $weekday at $time',
    );

    final now = tz.TZDateTime.now(tz.local);

    // Haftanın o gününün bir sonraki tarihini hesaplama
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    print('DEBUG: Next Weekly Notification Date: $scheduledDate');

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'weight_reminders',
        'Weight Reminders',
        channelDescription: 'Weekly reminders to update weight',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // Haftalık kilo takibi hatırlatıcısını planlama
  Future<void> scheduleWeeklyWeightReminder() async {
    // Pazartesi sabah 9:00 için planlama
    await scheduleWeeklyNotification(
      id: 100, // Kilo hatırlatıcısı için ID
      title: '⚖️ Kilo Takibi Zamanı!',
      body: 'Haftalık kilonu güncelleyerek gelişimini takip et.',
      weekday: 1, // Pazartesi
      time: const TimeOfDay(hour: 9, minute: 0),
    );
  }

  // Belirli bir bildirimi iptal etme
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  // Tüm bildirimleri iptal etme
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
