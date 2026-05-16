import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../../logging/app_logger.dart';

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    final prayerName = inputData?['prayerName']?.toString() ?? 'Namaz';

    try {
      await _showFullScreenPrayerNotification(prayerName);
      return Future.value(true);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Background prayer notification failed',
        error: error,
        stackTrace: stackTrace,
        context: {'task': task, 'prayerName': prayerName},
      );
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
Future<void> androidAlarmCallback(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prayerName = params['prayerName']?.toString() ?? 'Namaz';

  try {
    await _showFullScreenPrayerNotification(prayerName);
  } catch (error, stackTrace) {
    AppLogger.error(
      'Android alarm callback failed',
      error: error,
      stackTrace: stackTrace,
      context: {'alarmId': id, 'prayerName': prayerName},
    );
  }
}

Future<void> _showFullScreenPrayerNotification(String prayerName) async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();

  await plugin.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  await plugin.show(
    prayerName.hashCode,
    '$prayerName vakti',
    'Ezan vakti geldi. Açmak için dokunun.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'adhan_alarm_fullscreen',
        'Ezan Alarmı',
        channelDescription: 'Kilit ekranı ve tam ekran namaz vakti alarmları',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    ),
  );
}
