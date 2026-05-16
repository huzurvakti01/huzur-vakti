import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class FinanceRates {
  final double gramGoldTry;
  final double gramSilverTry;
  final DateTime fetchedAt;
  final bool fallback;

  const FinanceRates({
    required this.gramGoldTry,
    required this.gramSilverTry,
    required this.fetchedAt,
    required this.fallback,
  });

  double get nisabGoldTry => gramGoldTry * 80.18;
  double get nisabSilverTry => gramSilverTry * 595;
}

class FinanceRateService {
  static final Uri _primary = Uri.parse('https://api.exchangerate.host/latest?base=XAU&symbols=TRY');

  static const _goldKey = 'finance_gram_gold_try';
  static const _silverKey = 'finance_gram_silver_try';
  static const _fetchedAtKey = 'finance_rates_fetched_at';

  Future<FinanceRates> fetchRates() async {
    try {
      final response = await http.get(_primary).timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        AppLogger.warning(
          'Finance rate provider returned non-success status',
          context: {'statusCode': response.statusCode},
        );
        return _cachedOrThrow();
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = decoded['rates'] as Map<String, dynamic>? ?? {};
      final xauTry = (rates['TRY'] as num?)?.toDouble();

      if (xauTry == null || xauTry <= 0) {
        AppLogger.warning('Finance rate provider response is missing XAU/TRY');
        return _cachedOrThrow();
      }

      final gramGold = xauTry / 31.1034768;
      final gramSilver = gramGold / 86;

      final result = FinanceRates(
        gramGoldTry: gramGold,
        gramSilverTry: gramSilver,
        fetchedAt: DateTime.now(),
        fallback: false,
      );

      await _cache(result);
      return result;
    } on SocketException catch (error, stackTrace) {
      AppLogger.warning(
        'Finance rate network failure',
        error: error,
        stackTrace: stackTrace,
      );
      return _cachedOrThrow();
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Finance rate read failed',
        error: error,
        stackTrace: stackTrace,
      );
      return _cachedOrThrow();
    }
  }

  Future<void> _cache(FinanceRates rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goldKey, rates.gramGoldTry);
    await prefs.setDouble(_silverKey, rates.gramSilverTry);
    await prefs.setString(_fetchedAtKey, rates.fetchedAt.toIso8601String());
  }

  Future<FinanceRates> _cachedOrThrow() async {
    final prefs = await SharedPreferences.getInstance();
    final gold = prefs.getDouble(_goldKey);
    final silver = prefs.getDouble(_silverKey);
    final fetchedAt = prefs.getString(_fetchedAtKey);

    if (gold != null && silver != null && fetchedAt != null) {
      return FinanceRates(
        gramGoldTry: gold,
        gramSilverTry: silver,
        fetchedAt: DateTime.tryParse(fetchedAt) ?? DateTime.now(),
        fallback: true,
      );
    }

    throw const NetworkAppException();
  }
}
