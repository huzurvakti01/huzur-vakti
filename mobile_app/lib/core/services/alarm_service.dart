import 'package:flutter/foundation.dart';

import '../models/prayer_times.dart';
import 'audio/adhan_audio_service.dart';
import 'background_alarm_scheduler.dart';
import 'notification_service.dart';

class AlarmService extends ChangeNotifier {
  final AdhanAudioService audioService;
  final NotificationService notificationService;
  final BackgroundAlarmScheduler backgroundScheduler;

  AlarmService({
    required this.audioService,
    required this.notificationService,
    required this.backgroundScheduler,
  });

  bool _ringing = false;
  bool get ringing => _ringing;

  Future<void> init() async {
    await backgroundScheduler.init();
  }

  Future<void> scheduleDaily(PrayerTimes times) async {
    await backgroundScheduler.schedulePrayerAlarms(times);
  }

  Future<void> startAdhan(String prayerName) async {
    _ringing = true;
    notifyListeners();

    await notificationService.showPrayerReminder(
      title: '$prayerName vakti',
      body: 'Ezan okunuyor. Bu ekranda reklam gösterilmez.',
    );

    await audioService.playSelected(loop: true);
  }

  Future<void> stopAdhan() async {
    _ringing = false;
    notifyListeners();
    await audioService.stop();
  }
}
