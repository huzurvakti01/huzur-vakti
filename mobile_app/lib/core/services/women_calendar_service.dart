import 'package:hive_flutter/hive_flutter.dart';

import '../logging/app_logger.dart';

class WomenCalendarState {
  final DateTime startDate;
  final int cycleLength;
  final int periodLength;
  final DateTime nextStartDate;
  final bool worshipPausedToday;

  const WomenCalendarState({
    required this.startDate,
    required this.cycleLength,
    required this.periodLength,
    required this.nextStartDate,
    required this.worshipPausedToday,
  });
}

class WomenCalendarService {
  static const _boxName = 'women_calendar';
  static const _startDate = 'start_date';
  static const _cycleLength = 'cycle_length';
  static const _periodLength = 'period_length';

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_boxName);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Women calendar hive init failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Box get _box => Hive.box(_boxName);

  WomenCalendarState load() {
    final raw = _box.get(_startDate) as String?;
    final start = raw == null ? DateTime.now() : DateTime.tryParse(raw) ?? DateTime.now();
    final cycle = (_box.get(_cycleLength) as int?) ?? 28;
    final period = (_box.get(_periodLength) as int?) ?? 6;

    return _state(start, cycle, period);
  }

  Future<WomenCalendarState> save({
    required DateTime startDate,
    required int cycleLength,
    required int periodLength,
  }) async {
    await _box.put(_startDate, startDate.toIso8601String());
    await _box.put(_cycleLength, cycleLength);
    await _box.put(_periodLength, periodLength);

    return _state(startDate, cycleLength, periodLength);
  }

  WomenCalendarState _state(DateTime start, int cycle, int period) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    var anchor = DateTime(start.year, start.month, start.day);

    while (anchor.add(Duration(days: cycle)).isBefore(normalizedToday)) {
      anchor = anchor.add(Duration(days: cycle));
    }

    final daysFromAnchor = normalizedToday.difference(anchor).inDays;
    final paused = daysFromAnchor >= 0 && daysFromAnchor < period;

    return WomenCalendarState(
      startDate: anchor,
      cycleLength: cycle,
      periodLength: period,
      nextStartDate: anchor.add(Duration(days: cycle)),
      worshipPausedToday: paused,
    );
  }
}
