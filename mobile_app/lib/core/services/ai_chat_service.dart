import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import 'ai_client_service.dart';
import 'data_repository_hub.dart';

class AiChatLimitStatus {
  final int used;
  final int dailyLimit;
  final bool isPremium;

  const AiChatLimitStatus({
    required this.used,
    required this.dailyLimit,
    required this.isPremium,
  });

  int get remaining => isPremium ? 999999 : (dailyLimit - used).clamp(0, dailyLimit);
  bool get exhausted => !isPremium && used >= dailyLimit;
}

class AiChatService {
  AiChatService({
    required AiClientService secureClient,
  }) : _secureClient = secureClient;

  final AiClientService _secureClient;

  static const int freeDailyLimit = 3;
  static const _dateKey = 'ai_chat_limit_date';
  static const _countKey = 'ai_chat_limit_count';

  Future<AiChatLimitStatus> limitStatus({required bool isPremium}) async {
    if (isPremium) {
      return const AiChatLimitStatus(
        used: 0,
        dailyLimit: freeDailyLimit,
        isPremium: true,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_dateKey);

    if (storedDate != today) {
      await prefs.setString(_dateKey, today);
      await prefs.setInt(_countKey, 0);

      return const AiChatLimitStatus(
        used: 0,
        dailyLimit: freeDailyLimit,
        isPremium: false,
      );
    }

    return AiChatLimitStatus(
      used: prefs.getInt(_countKey) ?? 0,
      dailyLimit: freeDailyLimit,
      isPremium: false,
    );
  }

  Future<String> sendMessage({
    required String question,
    required bool isPremium,
    required String languageCode,
  }) async {
    final status = await limitStatus(isPremium: isPremium);

    if (status.exhausted) {
      throw const AppException(
        AppStrings.aiDailyLimitMessage,
        code: 'ai_daily_limit_exceeded',
      );
    }

    final answer = await _secureClient.sendMessage(
      message: question,
      languageCode: languageCode,
      screen: 'ai_chat',
    );

    if (!isPremium) {
      await _increaseCounter();
    }

    return DataRepositoryHub().appendAiFatwaDisclaimer(answer);
  }

  Future<void> _increaseCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_dateKey);

    if (storedDate != today) {
      await prefs.setString(_dateKey, today);
      await prefs.setInt(_countKey, 1);
      return;
    }

    final used = prefs.getInt(_countKey) ?? 0;
    await prefs.setInt(_countKey, used + 1);
  }

  String _todayKey() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
