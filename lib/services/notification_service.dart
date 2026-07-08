import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import '../models/recurring_transaction_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
            // Handle notification tap
          },
    );

    // Request Android notification permission
    final androidPlatform = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlatform?.requestNotificationsPermission();
    await androidPlatform?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleReminder(
    RecurringTransactionModel trx,
    int notificationId,
  ) async {
    if (!trx.hasReminder || trx.reminderDateTime == null) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      trx.nextOccurrence.year,
      trx.nextOccurrence.month,
      trx.nextOccurrence.day,
      trx.reminderDateTime!.hour,
      trx.reminderDateTime!.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Reminder: ${trx.title}',
        'Jangan lupa catat transaksi ${trx.title} sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(trx.amount)}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'recurring_transaction_channel',
            'Transaksi Rutin',
            channelDescription: 'Reminder untuk transaksi rutin',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(trx.recurrenceType),
      );
    } catch (e, stackTrace) {
      debugPrint('Error scheduling notification: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static DateTimeComponents? _getDateTimeComponents(
    RecurrenceType recurrenceType,
  ) {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return DateTimeComponents.time;
      case RecurrenceType.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RecurrenceType.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case RecurrenceType.yearly:
        return DateTimeComponents.dateAndTime;
    }
  }

  static Future<void> cancelReminder(int notificationId) async {
    try {
      await _notificationsPlugin.cancel(notificationId);
    } catch (e) {
      debugPrint('Error canceling reminder: $e');
    }
  }

  static Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all reminders: $e');
    }
  }
}
