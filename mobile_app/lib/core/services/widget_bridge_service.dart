import 'package:home_widget/home_widget.dart';

import '../logging/app_logger.dart';
import '../models/prayer_times.dart';

class WidgetBridgeService {
  static const appGroupId = 'group.com.huzurvakti.app';
  static const androidWidget = 'HuzurPrayerWidget';
  static const iosWidget = 'HuzurPrayerWidget';

  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Widget bridge init failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> update(PrayerTimes times) async {
    final next = times.nextPrayer(DateTime.now());
    final remaining = next.time.difference(DateTime.now());

    try {
      await HomeWidget.saveWidgetData<String>('nextPrayerName', next.name);
      await HomeWidget.saveWidgetData<String>('nextPrayerTime', _fmt(next.time));
      await HomeWidget.saveWidgetData<String>('remainingMinutes', '${remaining.inMinutes}');
      await HomeWidget.saveWidgetData<String>('deepLink', 'huzurvakti://widget/open?source=home_widget');
      await HomeWidget.updateWidget(androidName: androidWidget, iOSName: iosWidget);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Home widget update failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
