import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/app_logger.dart';

/// Local notifications for task reminders, automation completions and
/// background-sync results. Remote push (FCM) is intentionally out of
/// scope here — it requires a Firebase project the user must provision —
/// but this service is what a push handler would hand off to for display,
/// so wiring FCM later is a one-file change.
class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channel = AndroidNotificationDetails(
    'jarvis_default',
    'JARVIS',
    channelDescription: 'Assistant activity, task reminders and automation results',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimeZone));
    } catch (e) {
      AppLogger.warning('Could not resolve device timezone, defaulting to UTC', e);
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    final androidGranted = await android?.requestNotificationsPermission() ?? true;
    final iosGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    return androidGranted && iosGranted;
  }

  Future<void> show({required int id, required String title, required String body}) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: _channel),
      );
    } catch (e) {
      AppLogger.warning('Failed to show notification', e);
    }
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledFor,
  }) async {
    if (scheduledFor.isBefore(DateTime.now())) {
      await show(id: id, title: title, body: body);
      return;
    }
    final scheduledDate = tz.TZDateTime.from(scheduledFor, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
}

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
