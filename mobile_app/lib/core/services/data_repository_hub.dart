import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import '../models/prayer_times.dart';
import '../models/quran_models.dart';

enum RepositorySource {
  network,
  localFallback,
}

class RepositoryResult<T> {
  final T data;
  final RepositorySource source;
  final String? warning;

  const RepositoryResult({
    required this.data,
    required this.source,
    this.warning,
  });

  bool get fromFallback => source == RepositorySource.localFallback;
}

class DataRepositoryHub {
  DataRepositoryHub({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const aiFatwaDisclaimer =
      'Bu cevap bir yapay zeka asistanı tarafından fıkıh kaynakları taranarak hazırlanmıştır. '
      'Bağlayıcı bir fetva niteliği taşımamaktadır. '
      'Hassas meselelerde resmi dini kurumlara danışılması tavsiye edilir.';

  Future<bool> hasInternetConnection() async {
    try {
      final response = await _client
          .get(Uri.parse('https://www.google.com/generate_204'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 204 || response.statusCode == 200;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Connectivity probe failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<RepositoryResult<PrayerTimes>> fetchPrayerTimesWithFallback({
    required Uri networkUri,
    required DateTime date,
  }) async {
    if (await hasInternetConnection()) {
      try {
        final response = await _client.get(networkUri).timeout(const Duration(seconds: 16));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final timings = decoded['data']['timings'] as Map<String, dynamic>;

          return RepositoryResult(
            data: _parsePrayerTimesFromAlAdhan(timings: timings, date: date),
            source: RepositorySource.network,
          );
        }

        AppLogger.warning(
          'Prayer network source returned non-success; local fallback will be used',
          context: {'statusCode': response.statusCode},
        );
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Prayer network source failed; local fallback will be used',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return RepositoryResult(
      data: await localPrayerTimes(date),
      source: RepositorySource.localFallback,
      warning: AppStrings.offlineFallbackPrayerWarning,
    );
  }

  Future<PrayerTimes> localPrayerTimes(DateTime date) async {
    final decoded = await _loadJsonMap('assets/json/prayer_fallback.json');
    final timings = decoded['times'] as Map<String, dynamic>;

    return _parsePrayerTimesFromClockMap(timings: timings, date: date);
  }

  Future<RepositoryResult<List<QuranSurah>>> fetchSurahsWithFallback({
    required Uri networkUri,
  }) async {
    if (await hasInternetConnection()) {
      try {
        final response = await _client.get(networkUri).timeout(const Duration(seconds: 16));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final data = decoded['data'] as List<dynamic>? ?? [];

          return RepositoryResult(
            data: data
                .map((item) => QuranSurah.fromJson(item as Map<String, dynamic>))
                .where((surah) => surah.ayahCount > 0)
                .toList(growable: false),
            source: RepositorySource.network,
          );
        }
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Quran surah list network failed; local fallback will be used',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return RepositoryResult(
      data: await localSurahList(),
      source: RepositorySource.localFallback,
      warning: AppStrings.offlineFallbackQuranWarning,
    );
  }

  Future<List<QuranSurah>> localSurahList() async {
    final decoded = await _loadJsonMap('assets/json/quran_surahs.json');
    final data = decoded['data'] as List<dynamic>? ?? [];

    return data
        .map((item) => QuranSurah.fromJson(item as Map<String, dynamic>))
        .where((surah) => surah.ayahCount > 0)
        .toList(growable: false);
  }

  Future<RepositoryResult<QuranSurahDetail>> fetchSurahDetailWithFallback({
    required Uri networkUri,
    required QuranSurah surah,
  }) async {
    if (await hasInternetConnection()) {
      try {
        final response = await _client.get(networkUri).timeout(const Duration(seconds: 16));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final data = decoded['data'] as Map<String, dynamic>;
          final ayahs = (data['ayahs'] as List<dynamic>? ?? [])
              .map((item) => QuranAyah.fromJson(item as Map<String, dynamic>))
              .toList(growable: false);

          return RepositoryResult(
            data: QuranSurahDetail(surah: surah, ayahs: ayahs),
            source: RepositorySource.network,
          );
        }
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Quran detail network failed; local fallback will be used',
          error: error,
          stackTrace: stackTrace,
          context: {'surah': surah.number},
        );
      }
    }

    return RepositoryResult(
      data: await localSurahDetail(surah),
      source: RepositorySource.localFallback,
      warning: AppStrings.offlineFallbackQuranWarning,
    );
  }

  Future<QuranSurahDetail> localSurahDetail(QuranSurah surah) async {
    final decoded = await _loadJsonMap('assets/json/quran_tr.json');
    final item = decoded['${surah.number}'] as Map<String, dynamic>?;

    if (item == null) {
      final fallbackSurah = (await localSurahList()).first;
      return localSurahDetail(fallbackSurah);
    }

    final arabic = (item['arabic'] as List<dynamic>? ?? []).cast<String>();
    final ayahs = List<QuranAyah>.generate(
      arabic.length,
      (index) => QuranAyah(
        numberInSurah: index + 1,
        text: arabic[index],
      ),
    );

    return QuranSurahDetail(surah: surah, ayahs: ayahs);
  }

  Future<RepositoryResult<List<String>>> fetchTranslationWithFallback({
    required Uri networkUri,
    required int surahNumber,
    required String languageCode,
  }) async {
    if (await hasInternetConnection()) {
      try {
        final response = await _client.get(networkUri).timeout(const Duration(seconds: 16));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final data = decoded['data'] as Map<String, dynamic>;
          final ayahs = data['ayahs'] as List<dynamic>? ?? [];

          return RepositoryResult(
            data: ayahs
                .map((item) => ((item as Map<String, dynamic>)['text'] ?? '').toString())
                .toList(growable: false),
            source: RepositorySource.network,
          );
        }
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Quran translation network failed; local fallback will be used',
          error: error,
          stackTrace: stackTrace,
          context: {'surah': surahNumber, 'languageCode': languageCode},
        );
      }
    }

    return RepositoryResult(
      data: await localTranslation(surahNumber, languageCode),
      source: RepositorySource.localFallback,
      warning: AppStrings.offlineFallbackQuranWarning,
    );
  }

  Future<List<String>> localTranslation(int surahNumber, String languageCode) async {
    final decoded = await _loadJsonMap('assets/json/quran_tr.json');
    final item = decoded['$surahNumber'] as Map<String, dynamic>?;

    if (item == null) {
      return (decoded['1'] as Map<String, dynamic>?)?['translation']?.cast<String>() ?? const <String>[];
    }

    return (item['translation'] as List<dynamic>? ?? const <dynamic>[]).cast<String>();
  }

  Future<Map<String, String>> localDailyContent(String languageCode) async {
    final decoded = await _loadJsonMap('assets/json/content_fallback.json');
    final local = decoded[languageCode] as Map<String, dynamic>?;
    final fallback = decoded['en'] as Map<String, dynamic>;

    return (local ?? fallback).map((key, value) => MapEntry(key, value.toString()));
  }

  String appendAiFatwaDisclaimer(String answer) {
    final trimmed = answer.trim();

    if (trimmed.contains(aiFatwaDisclaimer)) {
      return trimmed;
    }

    return '$trimmed\n\n—\n$aiFatwaDisclaimer';
  }

  Future<Map<String, dynamic>> _loadJsonMap(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  PrayerTimes _parsePrayerTimesFromAlAdhan({
    required Map<String, dynamic> timings,
    required DateTime date,
  }) {
    DateTime parse(String key) {
      final raw = timings[key].toString().split(' ').first;
      final parts = raw.split(':');

      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    return PrayerTimes(
      date: date,
      times: {
        'Fajr': parse('Fajr'),
        'Sunrise': parse('Sunrise'),
        'Dhuhr': parse('Dhuhr'),
        'Asr': parse('Asr'),
        'Maghrib': parse('Maghrib'),
        'Isha': parse('Isha'),
      },
    );
  }

  PrayerTimes _parsePrayerTimesFromClockMap({
    required Map<String, dynamic> timings,
    required DateTime date,
  }) {
    DateTime parse(String key) {
      final parts = timings[key].toString().split(':');

      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    return PrayerTimes(
      date: date,
      times: {
        'Fajr': parse('Fajr'),
        'Sunrise': parse('Sunrise'),
        'Dhuhr': parse('Dhuhr'),
        'Asr': parse('Asr'),
        'Maghrib': parse('Maghrib'),
        'Isha': parse('Isha'),
      },
    );
  }
}
