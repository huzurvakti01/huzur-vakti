import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../constants/app_strings.dart';
import '../logging/app_logger.dart';
import 'quran_api_service.dart';
import 'data_repository_hub.dart';

class DashboardReligiousContent {
  final String type;
  final String text;
  final String source;
  final String route;

  const DashboardReligiousContent({
    required this.type,
    required this.text,
    required this.source,
    required this.route,
  });

  Future<List<DashboardReligiousContent>> _localizedFallback(String languageCode) async {
    try {
      final content = await _hub.localDailyContent(languageCode);

      return [
        DashboardReligiousContent(
          type: AppStrings.dashboardAyahCard,
          text: content['ayah'] ?? AppStrings.dashboardAyahText,
          source: 'assets/json',
          route: '/quran',
        ),
        DashboardReligiousContent(
          type: AppStrings.dashboardHadithCard,
          text: content['hadith'] ?? AppStrings.dashboardHadithText,
          source: 'assets/json',
          route: '/khutbah',
        ),
        DashboardReligiousContent(
          type: AppStrings.dashboardDuaCard,
          text: content['dua'] ?? AppStrings.dashboardDuaText,
          source: 'assets/json',
          route: '/assistant-support',
        ),
      ];
    } catch (_) {
      return fallback;
    }
  }

}

class ReligiousContentService {
  ReligiousContentService({
    http.Client? client,
    QuranApiService? quran,
    DataRepositoryHub? repositoryHub,
  })  : _client = client ?? http.Client(),
        _quran = quran ?? QuranApiService(),
        _hub = repositoryHub ?? DataRepositoryHub();

  final http.Client _client;
  final QuranApiService _quran;
  final DataRepositoryHub _hub;

  static const fallback = [
    DashboardReligiousContent(
      type: AppStrings.dashboardAyahCard,
      text: AppStrings.dashboardAyahText,
      source: 'Fallback',
      route: '/quran',
    ),
    DashboardReligiousContent(
      type: AppStrings.dashboardHadithCard,
      text: AppStrings.dashboardHadithText,
      source: 'Fallback',
      route: '/khutbah',
    ),
    DashboardReligiousContent(
      type: AppStrings.dashboardDuaCard,
      text: AppStrings.dashboardDuaText,
      source: 'Fallback',
      route: '/assistant-support',
    ),
  ];

  Future<List<DashboardReligiousContent>> fetchDashboardContent(String languageCode) async {
    final results = <DashboardReligiousContent>[];

    final ayah = await _fetchDailyAyah(languageCode);
    if (ayah != null) results.add(ayah);

    final hadith = await _fetchDailyHadith(languageCode);
    if (hadith != null) results.add(hadith);

    final khutbah = await _fetchKhutbahHeadline(languageCode);
    if (khutbah != null) results.add(khutbah);

    if (results.isEmpty) return _localizedFallback(languageCode);
    if (results.length < 3) {
      results.addAll(fallback.where((item) => !results.any((r) => r.type == item.type)));
    }

    return results.take(3).toList(growable: false);
  }

  Future<DashboardReligiousContent?> _fetchDailyAyah(String languageCode) async {
    try {
      final edition = _quran.translationEditionForLocale(languageCode);
      final rng = Random(DateTime.now().day + DateTime.now().month * 31);
      final surah = 1 + rng.nextInt(114);
      final uri = Uri.parse('https://api.alquran.cloud/v1/surah/$surah/$edition');
      final response = await _client.get(uri).timeout(const Duration(seconds: 14));

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final ayahs = data['ayahs'] as List<dynamic>? ?? [];
      if (ayahs.isEmpty) return null;

      final ayah = ayahs[rng.nextInt(ayahs.length)] as Map<String, dynamic>;
      final text = (ayah['text'] ?? '').toString().trim();
      if (text.isEmpty) return null;

      return DashboardReligiousContent(
        type: AppStrings.dashboardAyahCard,
        text: text,
        source: AppStrings.religiousContentAyahSource,
        route: '/quran',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Daily ayah fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<DashboardReligiousContent?> _fetchDailyHadith(String languageCode) async {
    try {
      final response = await _client
          .get(Uri.parse('https://api.hadith.gading.dev/books/bukhari/1'))
          .timeout(const Duration(seconds: 14));

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      final contents = data['contents'] as Map<String, dynamic>? ?? {};
      final arab = (contents['arab'] ?? '').toString().trim();
      final id = (contents['id'] ?? '').toString().trim();
      final text = languageCode == 'ar' && arab.isNotEmpty ? arab : id;

      if (text.isEmpty) return null;

      return DashboardReligiousContent(
        type: AppStrings.dashboardHadithCard,
        text: text,
        source: AppStrings.religiousContentHadithSource,
        route: '/khutbah',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Daily hadith fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<DashboardReligiousContent?> _fetchKhutbahHeadline(String languageCode) async {
    try {
      final response = await _client
          .get(Uri.parse('https://www.diyanet.gov.tr/tr-TR/Kurumsal/Detay//hutbeler'))
          .timeout(const Duration(seconds: 14));

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final body = utf8.decode(response.bodyBytes);
      final clean = body.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (clean.isEmpty) return null;

      return DashboardReligiousContent(
        type: AppStrings.khutbahTitle,
        text: clean.length > 180 ? clean.substring(0, 180) : clean,
        source: AppStrings.religiousContentKhutbahSource,
        route: '/khutbah',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Khutbah headline fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
