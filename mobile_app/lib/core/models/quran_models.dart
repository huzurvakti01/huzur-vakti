class QuranSurah {
  final int number;
  final String name;
  final String englishName;
  final String revelationType;
  final int ayahCount;

  const QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.ayahCount,
  });

  factory QuranSurah.fromJson(Map<String, dynamic> json) {
    return QuranSurah(
      number: (json['number'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      englishName: (json['englishName'] ?? '').toString(),
      revelationType: (json['revelationType'] ?? '').toString(),
      ayahCount: (json['numberOfAyahs'] as num? ?? 0).toInt(),
    );
  }
}

class QuranAyah {
  final int numberInSurah;
  final String text;

  const QuranAyah({
    required this.numberInSurah,
    required this.text,
  });

  factory QuranAyah.fromJson(Map<String, dynamic> json) {
    return QuranAyah(
      numberInSurah: (json['numberInSurah'] as num).toInt(),
      text: (json['text'] ?? '').toString(),
    );
  }
}

class QuranSurahDetail {
  final QuranSurah surah;
  final List<QuranAyah> ayahs;

  const QuranSurahDetail({
    required this.surah,
    required this.ayahs,
  });
}
