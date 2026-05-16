import '../models/prayer_times.dart';

class TahajjudPlan {
  final DateTime maghrib;
  final DateTime fajr;
  final DateTime lastThirdStart;
  final DateTime sleepSuggestion;
  final DateTime wakeSuggestion;

  const TahajjudPlan({
    required this.maghrib,
    required this.fajr,
    required this.lastThirdStart,
    required this.sleepSuggestion,
    required this.wakeSuggestion,
  });
}

class TahajjudService {
  TahajjudPlan build({
    required PrayerTimes today,
    required PrayerTimes tomorrow,
  }) {
    final maghrib = today.times['Maghrib']!;
    final fajr = tomorrow.times['Fajr']!;
    final night = fajr.difference(maghrib);
    final lastThird = fajr.subtract(Duration(milliseconds: night.inMilliseconds ~/ 3));
    return TahajjudPlan(
      maghrib: maghrib,
      fajr: fajr,
      lastThirdStart: lastThird,
      sleepSuggestion: lastThird.subtract(const Duration(minutes: 360)),
      wakeSuggestion: lastThird.add(const Duration(minutes: 10)),
    );
  }
}
