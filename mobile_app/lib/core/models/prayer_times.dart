class PrayerMoment {
  final String name;
  final DateTime time;

  const PrayerMoment({
    required this.name,
    required this.time,
  });
}

class PrayerTimes {
  final DateTime date;
  final Map<String, DateTime> times;

  const PrayerTimes({
    required this.date,
    required this.times,
  });

  List<PrayerMoment> get ordered {
    final keys = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final names = {
      'Fajr': 'İmsak',
      'Sunrise': 'Güneş',
      'Dhuhr': 'Öğle',
      'Asr': 'İkindi',
      'Maghrib': 'Akşam',
      'Isha': 'Yatsı',
    };
    return keys
        .where((key) => times[key] != null)
        .map((key) => PrayerMoment(name: names[key]!, time: times[key]!))
        .toList();
  }

  PrayerMoment nextPrayer(DateTime now) {
    for (final item in ordered) {
      if (item.time.isAfter(now)) return item;
    }
    return ordered.first.copyWithNextDay();
  }
}

extension PrayerMomentNextDay on PrayerMoment {
  PrayerMoment copyWithNextDay() {
    return PrayerMoment(name: name, time: time.add(const Duration(days: 1)));
  }
}
