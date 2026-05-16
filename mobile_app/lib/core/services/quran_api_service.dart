import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import '../models/quran_models.dart';
import 'data_repository_hub.dart';

class QuranApiService {
  QuranApiService({
    DataRepositoryHub? repositoryHub,
  }) : _hub = repositoryHub ?? DataRepositoryHub();

  final DataRepositoryHub _hub;

  static final Uri _surahListUri = Uri.parse('https://api.alquran.cloud/v1/surah');

  Future<List<QuranSurah>> fetchSurahs() async {
    final result = await _hub.fetchSurahsWithFallback(networkUri: _surahListUri);
    return result.data;
  }

  Future<QuranSurahDetail> fetchSurahDetail(QuranSurah surah) async {
    final uri = Uri.parse('https://api.alquran.cloud/v1/surah/${surah.number}/quran-uthmani');
    final result = await _hub.fetchSurahDetailWithFallback(
      networkUri: uri,
      surah: surah,
    );
    return result.data;
  }
}

extension QuranAdvancedApi on QuranApiService {
  String translationEditionForLocale(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return 'tr.diyanet';
      case 'en':
        return 'en.sahih';
      case 'fr':
        return 'fr.hamidullah';
      case 'ar':
        return 'ar.muyassar';
      case 'ur':
        return 'ur.jalandhry';
      case 'id':
        return 'id.indonesian';
      default:
        return 'en.sahih';
    }
  }

  Future<List<String>> fetchSurahTranslationForLocale(
    int surahNumber,
    String languageCode,
  ) {
    return fetchSurahTranslationByEdition(
      surahNumber,
      translationEditionForLocale(languageCode),
    );
  }

  Future<List<String>> fetchSurahTranslationByEdition(
    int surahNumber,
    String edition,
  ) async {
    final uri = Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber/$edition');
    final languageCode = edition.split('.').first;
    final result = await _hub.fetchTranslationWithFallback(
      networkUri: uri,
      surahNumber: surahNumber,
      languageCode: languageCode,
    );
    return result.data;
  }


  Future<List<String>> fetchSurahTranslationTr(int surahNumber) async {
    return fetchSurahTranslationByEdition(surahNumber, 'tr.diyanet');
  }

  Future<List<String>> _legacyFetchSurahTranslationTr(int surahNumber) async {
    final uri = Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber/tr.diyanet');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 16));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AppException('Türkçe meal alınamadı.', code: 'quran_translation_failed');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final ayahs = data['ayahs'] as List<dynamic>? ?? [];
      return ayahs.map((item) => ((item as Map<String, dynamic>)['text'] ?? '').toString()).toList(growable: false);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Quran Turkish translation failed',
        error: error,
        stackTrace: stackTrace,
        context: {'surah': surahNumber},
      );
      if (error is AppException) rethrow;
      throw AppException('Türkçe meal alınamadı.', cause: error, stackTrace: stackTrace, code: 'quran_translation_failed');
    }
  }

  Future<List<String>> fetchSurahAudioAlafasy(int surahNumber) async {
    final uri = Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber/ar.alafasy');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 16));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AppException('Sesli okuma bağlantıları alınamadı.', code: 'quran_audio_failed');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final ayahs = data['ayahs'] as List<dynamic>? ?? [];
      return ayahs.map((item) => ((item as Map<String, dynamic>)['audio'] ?? '').toString()).toList(growable: false);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Quran audio urls failed',
        error: error,
        stackTrace: stackTrace,
        context: {'surah': surahNumber},
      );
      if (error is AppException) rethrow;
      throw AppException('Sesli okuma bağlantıları alınamadı.', cause: error, stackTrace: stackTrace, code: 'quran_audio_failed');
    }
  }

  Future<List<String>> fetchSurahTafsirNote(int surahNumber) async {
    final translations = await fetchSurahTranslationTr(surahNumber);
    return translations
        .map((text) => text.isEmpty ? '' : 'Meal özeti: $text')
        .toList(growable: false);
  }
}
