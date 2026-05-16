import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/prayer_times.dart';
import '../services/alarm_service.dart';
import '../services/location_service.dart';
import '../services/prayer_api_service.dart';
import '../services/global_settings_service.dart';
import '../services/widget_bridge_service.dart';
import '../logging/app_logger.dart';

class PrayerController extends ChangeNotifier {
  final PrayerApiService api;
  final LocationService locationService;
  final WidgetBridgeService widgetBridge;
  final AlarmService alarmService;
  final GlobalSettingsService globalSettings;

  PrayerController({
    required this.api,
    required this.locationService,
    required this.widgetBridge,
    required this.alarmService,
    required this.globalSettings,
  });

  PrayerTimes? _times;
  bool _loading = false;
  String? _error;
  Timer? _timer;

  PrayerTimes? get times => _times;
  bool get loading => _loading;
  String? get error => _error;
  PrayerMoment? get next => _times?.nextPrayer(DateTime.now());

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final pos = await locationService.currentPosition();
      _times = await api.fetchPrayerTimes(
        latitude: pos.latitude,
        longitude: pos.longitude,
        date: DateTime.now(),
        calculationMethod: globalSettings.method.id,
        hijriOffset: globalSettings.hijriOffset,
      );

      await widgetBridge.update(_times!);
      await alarmService.scheduleDaily(_times!);

      _timer ??= Timer.periodic(
        const Duration(seconds: 30),
        (_) => notifyListeners(),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'PrayerController load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    }

    _loading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
