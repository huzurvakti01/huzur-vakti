import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> showPrayerReminder({
    required String title,
    required String body,
  }) async {
    await plugin.show(
      title.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Namaz Vakti',
          channelDescription: 'Namaz vakti ve ibadet hatırlatmaları',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: false),
      ),
    );
  }
}
