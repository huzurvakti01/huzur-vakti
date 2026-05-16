import '../models/prayer_times.dart';
import 'background_alarm_manager.dart';

class BackgroundAlarmScheduler {
  BackgroundAlarmScheduler({
    BackgroundAlarmManager? manager,
  }) : _manager = manager ?? BackgroundAlarmManager();

  final BackgroundAlarmManager _manager;

  Future<void> init() => _manager.init();

  Future<void> schedulePrayerAlarms(PrayerTimes times) {
    return _manager.schedulePrayerAlarms(times);
  }

  Future<void> requestExactAlarmPermission() {
    return _manager.requestExactAlarmPermission();
  }

  Future<void> openBatteryOptimizationSettings() {
    return _manager.openBatteryOptimizationSettings();
  }

  Future<bool> canScheduleExactAlarms() {
    return _manager.canScheduleExactAlarms();
  }
}
