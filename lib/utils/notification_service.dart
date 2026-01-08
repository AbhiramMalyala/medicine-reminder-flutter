// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _plugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

//     const initSettings = InitializationSettings(
//       android: androidInit,
//     );

//     await _plugin.initialize(initSettings);
//   }

//   static Future<void> showMissedDoseNotification(
//     String title,
//     String body,
//   ) async {
//     const androidDetails = AndroidNotificationDetails(
//       'missed_dose_channel',
//       'Missed Dose Alerts',
//       channelDescription: 'Alerts for missed medicine doses',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const details = NotificationDetails(
//       android: androidDetails,
//     );

//     await _plugin.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       title,
//       body,
//       details,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ---------------- INIT ----------------
  static Future<void> init() async {
    if (_initialized) return;

    await _requestPermissions();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // ---------------- PERMISSIONS ----------------
  static Future<void> _requestPermissions() async {
    final status = await Permission.notification.status;

    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ---------------- MISSED DOSE ----------------
  static Future<void> showMissedDoseNotification(
    String title,
    String body,
  ) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'missed_dose_channel',
      'Missed Dose Alerts',
      channelDescription: 'Alerts for missed medicine doses',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
      color: const Color(0xFFEF5350), // RED
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: 'missed_dose',
    );
  }

  // ---------------- GENERIC STYLED ----------------
  static Future<void> showStyledNotification({
    required String title,
    required String body,
    String? bigText,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      'medicine_alerts',
      'Medicine Alerts',
      channelDescription: 'All medicine related alerts',
      importance: priority == NotificationPriority.high
          ? Importance.max
          : Importance.defaultImportance,
      priority: priority == NotificationPriority.high
          ? Priority.high
          : Priority.defaultPriority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation:
          bigText != null ? BigTextStyleInformation(bigText) : null,
      color: const Color(0xFF42A5F5), // BLUE
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ---------------- REMINDER ----------------
  static Future<void> showReminderNotification(
    String patientName,
    String time,
  ) async {
    await showStyledNotification(
      title: '💊 Medicine Reminder',
      body: '$patientName needs to take medicine at $time',
      bigText:
          'Please ensure $patientName takes their medicine on time at $time.',
    );
  }

  // ---------------- SUCCESS ----------------
  static Future<void> showSuccessNotification(
    String patientName,
    String time,
  ) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'success_channel',
      'Medicine Taken',
      channelDescription: 'Medicine taken successfully',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      enableVibration: false,
      playSound: false,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4CAF50), // GREEN
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✅ Medicine Taken',
      '$patientName took medicine at $time',
      details,
    );
  }

  // ---------------- UTIL ----------------
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  static Future<bool> areNotificationsEnabled() async {
    return Permission.notification.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}

enum NotificationPriority {
  high,
  normal,
}
