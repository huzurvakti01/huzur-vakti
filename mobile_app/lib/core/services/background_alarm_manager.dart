import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../logging/app_logger.dart';
import '../models/prayer_times.dart';
import 'background/background_alarm_dispatcher.dart';

class BackgroundAlarmManager {
  BackgroundAlarmManager({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  static const alarmChannelId = 'adhan_exact_alarm';
  static const alarmChannelName = 'Ezan Exact Alarm';
  static const fullScreenChannelId = 'adhan_alarm_fullscreen';

  Future<void> init() async {
    if (_initialized) return;

    try {
      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              alarmChannelId,
              alarmChannelName,
              description: 'Doze Mode altında ezan vakti exact alarm bildirimleri',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Local notification exact alarm init failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      if (!kIsWeb && Platform.isAndroid) {
        await AndroidAlarmManager.initialize();
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'AndroidAlarmManager initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await Workmanager().initialize(
        backgroundCallbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Workmanager initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _initialized = true;
  }

  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      return await android?.canScheduleExactNotifications() ?? true;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Exact alarm permission check failed',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  Future<void> requestExactAlarmPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await android?.requestExactAlarmsPermission();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Exact alarm permission request failed; opening Android settings',
        error: error,
        stackTrace: stackTrace,
      );

      await openExactAlarmSettings();
    }
  }

  Future<void> openExactAlarmSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );

    await intent.launch();
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

    const intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    );

    await intent.launch();
  }

  Future<void> openAppNotificationSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

    const intent = AndroidIntent(
      action: 'android.settings.APP_NOTIFICATION_SETTINGS',
      arguments: {
        'android.provider.extra.APP_PACKAGE': 'com.huzurvakti.app',
      },
    );

    await intent.launch();
  }

  Future<void> schedulePrayerAlarms(PrayerTimes times) async {
    await init();

    final exactAllowed = await canScheduleExactAlarms();

    if (!exactAllowed) {
      await requestExactAlarmPermission();
    }

    for (final item in times.ordered) {
      if (item.name == 'Güneş') continue;
      if (!item.time.isAfter(DateTime.now())) continue;

      await scheduleExactPrayerAlarm(
        id: _alarmId(item.name, item.time),
        title: '${item.name} vakti',
        body: 'Ezan vakti geldi. Açmak için dokunun.',
        scheduledAt: item.time,
        prayerName: item.name,
      );
    }
  }

  Future<void> scheduleExactPrayerAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String prayerName,
  }) async {
    await init();

    final tzTime = tz.TZDateTime.from(scheduledAt, tz.local);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            alarmChannelId,
            alarmChannelName,
            channelDescription: 'Ezan vakti tam zamanlı alarm bildirimleri',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            enableVibration: true,
            playSound: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: prayerName,
      );
    } catch (notificationError, notificationStack) {
      AppLogger.warning(
        'flutter_local_notifications exact schedule failed; trying AndroidAlarmManager',
        error: notificationError,
        stackTrace: notificationStack,
        context: {'prayerName': prayerName},
      );

      await _scheduleAndroidAlarmFallback(
        id: id,
        scheduledAt: scheduledAt,
        prayerName: prayerName,
      );
    }
  }

  Future<void> _scheduleAndroidAlarmFallback({
    required int id,
    required DateTime scheduledAt,
    required String prayerName,
  }) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await AndroidAlarmManager.oneShotAt(
          scheduledAt,
          id,
          androidAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          allowWhileIdle: true,
          params: {'prayerName': prayerName},
        );
        return;
      }
    } catch (alarmError, alarmStack) {
      AppLogger.warning(
        'AndroidAlarmManager exact fallback failed; trying Workmanager',
        error: alarmError,
        stackTrace: alarmStack,
        context: {'prayerName': prayerName},
      );
    }

    try {
      await Workmanager().registerOneOffTask(
        'prayer_${id}_${scheduledAt.millisecondsSinceEpoch}',
        'prayerAlarm',
        initialDelay: scheduledAt.difference(DateTime.now()),
        inputData: {'prayerName': prayerName},
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } catch (workError, workStack) {
      AppLogger.error(
        'All background prayer alarm scheduling strategies failed',
        error: workError,
        stackTrace: workStack,
        context: {'prayerName': prayerName},
      );
    }
  }

  Future<void> cancelPrayerAlarm(int id) async {
    await _notifications.cancel(id);

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await AndroidAlarmManager.cancel(id);
      } catch (_) {}
    }
  }

  int _alarmId(String prayerName, DateTime time) {
    return Object.hash(
      prayerName,
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
    ) & 0x7fffffff;
  }
}
