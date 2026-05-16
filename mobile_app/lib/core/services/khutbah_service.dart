import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class KhutbahContent {
  final String title;
  final String summary;
  final Uri source;

  const KhutbahContent({
    required this.title,
    required this.summary,
    required this.source,
  });
}

class KhutbahService {
  Future<KhutbahContent> fetchLatest() async {
    final uri = Uri.parse('https://www.diyanet.gov.tr/tr-TR/Kurumsal/Detay//hutbeler');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AppException(
          AppStrings.khutbahUnavailable,
          code: 'khutbah_request_failed',
        );
      }

      final body = utf8.decode(response.bodyBytes);
      final titleMatch = RegExp(
        r'<title>(.*?)</title>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(body);
      final cleanTitle = titleMatch?.group(1)?.replaceAll(RegExp(r'\s+'), ' ').trim();

      return KhutbahContent(
        title: cleanTitle == null || cleanTitle.isEmpty ? AppStrings.khutbahTitle : cleanTitle,
        summary: _safeSummary(body),
        source: uri,
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Khutbah fetch failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.khutbahUnavailable,
        cause: error,
        stackTrace: stackTrace,
        code: 'khutbah_fetch_failed',
      );
    }
  }

  String _safeSummary(String html) {
    final withoutScripts = html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), ' ');

    final text = withoutScripts
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.isEmpty) {
      return AppStrings.khutbahUnavailable;
    }

    const maxLength = 260;
    if (text.length <= maxLength) {
      return text;
    }

    return '${text.substring(0, maxLength).trim()}…';
  }
}

class MoonPhaseService {
  String phaseName(DateTime date) {
    final lp = 2551443;
    final now = date.millisecondsSinceEpoch ~/ 1000;
    final newMoon = DateTime.utc(2001, 1, 24, 13, 7, 0).millisecondsSinceEpoch ~/ 1000;
    final phase = ((now - newMoon) % lp) / lp;

    if (phase < 0.03 || phase > 0.97) return AppStrings.moonNew;
    if (phase < 0.28) return AppStrings.moonFirstQuarter;
    if (phase < 0.53) return AppStrings.moonFull;
    if (phase < 0.78) return AppStrings.moonLastQuarter;
    return AppStrings.moonNew;
  }
}
