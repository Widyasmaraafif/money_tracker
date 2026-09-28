import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import '../utils/streak_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;
  static Future<void>? _initFuture;

  /// ID khusus pengingat harian, jangan dipakai recurring lain.
  static const int _dailyLogReminderId = 999001;

  static Future<void> ensureInitialized() {
    _initFuture ??= initialize();
    return _initFuture!;
  }

  static Future<void> initialize() async {
    if (!_tzInitialized) {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(
          tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier),
        );
      } catch (_) {
        // Fallback: tetap pakai default bila nama zona tak dikenal.
      }
      _tzInitialized = true;
    }

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

    // Request Android notification permission (never throw from init).
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlatform?.requestNotificationsPermission();
    } catch (_) {
      // Permission request must not break saving/app flow.
    }
  }

  /// Pengingat harian "belum catat hari ini", default jam 20:00.
  /// Dijadwalkan berulang tiap hari pada jam yang sama.
  /// [skipToday]: true bila hari ini sudah ada pencatatan, agar
  /// notifikasi pertama jatuh besok (lalu berulang harian).
  static Future<void> scheduleDailyLogReminder({
    int hour = 20,
    int minute = 0,
    bool skipToday = false,
  }) async {
    await ensureInitialized();
    try {
      await _notificationsPlugin.zonedSchedule(
        _dailyLogReminderId,
        'Belum catat hari ini?',
        'Yuk catat pengeluaranmu hari ini biar streak tidak putus!',
        _nextDailyTime(hour, minute, skipToday),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_log_channel',
            'Pengingat Harian',
            channelDescription: 'Pengingat mencatat transaksi harian',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling daily log reminder: $e');
    }
  }

  static Future<void> cancelDailyLogReminder() async {
    try {
      await _notificationsPlugin.cancel(_dailyLogReminderId);
    } catch (e) {
      debugPrint('Error canceling daily log reminder: $e');
    }
  }

  static tz.TZDateTime _nextDailyTime(int hour, int minute, bool skipToday) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (skipToday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      while (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }
    return scheduled;
  }

  static Future<void> scheduleReminder(
    RecurringTransactionModel trx,
    int notificationId,
  ) async {
    if (!trx.hasReminder || trx.reminderDateTime == null) return;
    await ensureInitialized();

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
        // Inexact mode: alarmClock needs exact-alarm permission and throws
        // (ExactAlarmNotPermitted) when not granted, even though caught.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

  /// Baca ulang status pencatatan hari ini lalu jadwalkan (atau batalkan)
  /// pengingat harian. Dipanggil tiap data transaksi berubah.
  static Future<void> refreshDailyLogReminder() async {
    try {
      await ensureInitialized();
      final settings = Hive.box('settings');
      final enabled =
          settings.get('dailyReminderEnabled', defaultValue: true) as bool? ??
          true;
      if (!enabled) {
        await cancelDailyLogReminder();
        return;
      }
      final hour =
          settings.get('dailyReminderHour', defaultValue: 20) as int? ?? 20;
      final minute =
          settings.get('dailyReminderMinute', defaultValue: 0) as int? ?? 0;
      List<TransactionModel> txs = [];
      try {
        txs = Hive.box<TransactionModel>('transactions').values.toList();
      } catch (_) {}
      final loggedToday = computeStreak(txs).loggedToday;
      await scheduleDailyLogReminder(
        hour: hour,
        minute: minute,
        skipToday: loggedToday,
      );
    } catch (e) {
      debugPrint('Error refreshing daily log reminder: $e');
    }
  }

  static Future<void> setDailyReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    try {
      final settings = Hive.box('settings');
      await settings.put('dailyReminderEnabled', enabled);
      if (hour != null) await settings.put('dailyReminderHour', hour);
      if (minute != null) await settings.put('dailyReminderMinute', minute);
    } catch (e) {
      debugPrint('Error saving daily reminder settings: $e');
    }
    await refreshDailyLogReminder();
  }

  static Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all reminders: $e');
    }
  }
}
