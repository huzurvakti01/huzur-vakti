class QazaProgress {
  final Map<String, int> qazaCounts;
  final int quranPagesToday;
  final int dhikrToday;
  final int dailyQuranPageTarget;
  final int dailyDhikrTarget;
  final int streakDays;
  final DateTime? lastActivityDate;
  final DateTime updatedAt;

  const QazaProgress({
    required this.qazaCounts,
    required this.quranPagesToday,
    required this.dhikrToday,
    required this.dailyQuranPageTarget,
    required this.dailyDhikrTarget,
    required this.streakDays,
    required this.lastActivityDate,
    required this.updatedAt,
  });

  double get completion {
    final quran = dailyQuranPageTarget == 0 ? 0 : quranPagesToday / dailyQuranPageTarget;
    final dhikr = dailyDhikrTarget == 0 ? 0 : dhikrToday / dailyDhikrTarget;
    return ((quran.clamp(0, 1) + dhikr.clamp(0, 1)) / 2).toDouble();
  }

  Map<String, dynamic> toMap() {
    return {
      'qazaCounts': qazaCounts,
      'quranPagesToday': quranPagesToday,
      'dhikrToday': dhikrToday,
      'dailyQuranPageTarget': dailyQuranPageTarget,
      'dailyDhikrTarget': dailyDhikrTarget,
      'streakDays': streakDays,
      'lastActivityDate': lastActivityDate?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory QazaProgress.fromMap(Map<String, dynamic> map) {
    final rawCounts = Map<String, dynamic>.from(map['qazaCounts'] as Map? ?? {});
    return QazaProgress(
      qazaCounts: rawCounts.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      quranPagesToday: (map['quranPagesToday'] as num?)?.toInt() ?? 0,
      dhikrToday: (map['dhikrToday'] as num?)?.toInt() ?? 0,
      dailyQuranPageTarget: (map['dailyQuranPageTarget'] as num?)?.toInt() ?? 5,
      dailyDhikrTarget: (map['dailyDhikrTarget'] as num?)?.toInt() ?? 100,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      lastActivityDate: map['lastActivityDate'] is String
          ? DateTime.tryParse(map['lastActivityDate'] as String)
          : null,
      updatedAt: map['updatedAt'] is String
          ? (DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  QazaProgress copyWith({
    Map<String, int>? qazaCounts,
    int? quranPagesToday,
    int? dhikrToday,
    int? dailyQuranPageTarget,
    int? dailyDhikrTarget,
    int? streakDays,
    DateTime? lastActivityDate,
    DateTime? updatedAt,
  }) {
    return QazaProgress(
      qazaCounts: qazaCounts ?? this.qazaCounts,
      quranPagesToday: quranPagesToday ?? this.quranPagesToday,
      dhikrToday: dhikrToday ?? this.dhikrToday,
      dailyQuranPageTarget: dailyQuranPageTarget ?? this.dailyQuranPageTarget,
      dailyDhikrTarget: dailyDhikrTarget ?? this.dailyDhikrTarget,
      streakDays: streakDays ?? this.streakDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
