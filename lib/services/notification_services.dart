import 'package:expense_manager_project/services/storage_services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter/material.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> init() async {
    // Initialize timezone
    tzdata.initializeTimeZones();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android configuration - use 'ic_launcher' which is the default launcher icon
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS configuration
    final DarwinInitializationSettings iosInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('🔔 Notification received: ${response.payload}');
        // Handle notification tap - reschedule for next day
        await _rescheduleAfterNotification();
      },
    );

    // Also reschedule on app start in case notification was dismissed or device rebooted
    await _rescheduleAfterNotification();

    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permissions for Android 13+
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // Request notification permission
      final notifResult = await android.requestNotificationsPermission();
      print('✅ Notification permission: $notifResult');

      // Request exact alarm permission
      try {
        final alarmResult = await android.requestExactAlarmsPermission();
        print('✅ Exact alarm permission: $alarmResult');
      } catch (e) {
        print('⚠️  Exact alarm permission request: $e');
      }
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final enabledStr = await StorageService.getSettingValue('reminders_enabled');
    final hourStr = await StorageService.getSettingValue('reminder_hour');
    final minuteStr = await StorageService.getSettingValue('reminder_minute');

    return {
      'enabled': enabledStr == 'true',
      'hour': int.tryParse(hourStr ?? '9') ?? 9,
      'minute': int.tryParse(minuteStr ?? '0') ?? 0,
    };
  }

  /// Save notification preferences
  Future<void> saveNotificationPreferences({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await StorageService.setSettingValue('reminders_enabled', enabled.toString());
    await StorageService.setSettingValue('reminder_hour', hour.toString());
    await StorageService.setSettingValue('reminder_minute', minute.toString());

    // Update the daily reminder
    await _setupDailyReminder();
  }

  /// Setup daily reminder
  Future<void> _setupDailyReminder() async {
    // Cancel existing notifications
    await flutterLocalNotificationsPlugin.cancel(0);

    final prefs = await getNotificationPreferences();
    final enabled = prefs['enabled'] as bool;

    if (!enabled) return;

    final hour = prefs['hour'] as int;
    final minute = prefs['minute'] as int;

    // Set up daily reminder
    _scheduleDailyReminder(hour, minute);

    print(
        'Daily reminder scheduled for $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Schedule daily reminder at specific time
  Future<void> _scheduleDailyReminder(int hour, int minute) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily expense reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      // Cancel any existing notification first
      await flutterLocalNotificationsPlugin.cancel(0);

      final now = tz.TZDateTime.now(tz.local);
      print('📅 Scheduling daily notification');
      print('⏰ Current time: $now');
      print('⏱️  Daily reminder time: $hour:${minute.toString().padLeft(2, '0')}');

      // For iOS, use zonedSchedule for first occurrence
      // For Android, we'll use periodicallyShow which handles daily recurrence properly

      try {
        // Android: Use periodicallyShow for true daily recurrence
        // This will fire every day at the same time (within inexact window)
        await flutterLocalNotificationsPlugin.periodicallyShow(
          0,
          'Expense Reminder',
          'Time to record your daily expenses!',
          RepeatInterval.daily,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
        print('✅ Daily notification scheduled (repeat every 24h)');
      } catch (e) {
        print('⚠️  periodicallyShow failed, trying zonedSchedule: $e');

        // Fallback for iOS or if periodicallyShow fails
        final scheduledTime = _nextInstanceOfTime(hour, minute);
        await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          'Expense Reminder',
          'Time to record your daily expenses!',
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('✅ Scheduled for: ${scheduledTime.toString()}');
      }
    } catch (e) {
      print('❌ Error scheduling reminder: $e');
      rethrow;
    }
  }

  /// Get next instance of specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Reschedule notification after it fires (for daily recurring)
  Future<void> _rescheduleAfterNotification() async {
    try {
      final prefs = await getNotificationPreferences();
      final enabled = prefs['reminders_enabled'] == 'true';

      if (enabled) {
        final hour = int.parse(prefs['reminder_hour'] ?? '9');
        final minute = int.parse(prefs['reminder_minute'] ?? '0');

        // Check if a notification is already scheduled
        final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
        if (pending.isNotEmpty) {
          // Notification already scheduled, don't reschedule
          return;
        }

        print('🔄 Rescheduling for next occurrence at $hour:${minute.toString().padLeft(2, '0')}');
        await _scheduleDailyReminder(hour, minute);
      }
    } catch (e) {
      print('⚠️  Error rescheduling: $e');
    }
  }

  /// Show test notification
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily expense reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      999, // notification id for test
      'Expense Reminder',
      'Time to record your daily expenses!',
      notificationDetails,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Update daily reminder time
  Future<void> updateDailyReminderTime(int hour, int minute) async {
    await saveNotificationPreferences(
      enabled: true,
      hour: hour,
      minute: minute,
    );
  }

  /// Enable/disable reminders
  Future<void> enableReminders(bool enabled) async {
    final prefs = await getNotificationPreferences();
    await saveNotificationPreferences(
      enabled: enabled,
      hour: prefs['hour'] as int,
      minute: prefs['minute'] as int,
    );
  }

  /// Request notification permissions from user with dialog
  Future<bool> requestPermissionsWithDialog(BuildContext context) async {
    print('🔐 Requesting notification permissions...');

    // Show dialog first
    bool userAllowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Allow daily expense reminders?\n\nYou will receive notifications at your chosen time each day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('YES'),
          ),
        ],
      ),
    ) ?? false;

    if (!userAllowed) {
      print('User declined permissions');
      return false;
    }

    try {
      // Request Android permissions
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // Request notification permission
        final notifResult = await android.requestNotificationsPermission();
        print('✅ Notification permission: $notifResult');

        // Request exact alarm permission
        try {
          final alarmResult = await android.requestExactAlarmsPermission();
          print('✅ Exact alarm permission: $alarmResult');
        } catch (e) {
          print('⚠️  Exact alarm request: $e');
        }

        return notifResult ?? true;
      }

      // Request iOS permissions
      final ios = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final result = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('✅ iOS permission result: $result');
        return result ?? false;
      }

      return true;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }
}
