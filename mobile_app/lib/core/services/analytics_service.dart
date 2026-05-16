import 'package:firebase_analytics/firebase_analytics.dart';

import '../logging/app_logger.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (error, stackTrace) {
      AppLogger.error('Analytics app_open failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> logScreen(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (error, stackTrace) {
      AppLogger.error('Analytics screen_view failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> logAiMessage({
    required String languageCode,
    required bool isPremium,
    required String screen,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_message_sent',
        parameters: {
          'language_code': languageCode,
          'is_premium': isPremium,
          'screen': screen,
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error('Analytics AI event failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> logPurchaseAttempt(String productId) async {
    try {
      await _analytics.logEvent(
        name: 'purchase_attempt',
        parameters: {'product_id': productId},
      );
    } catch (error, stackTrace) {
      AppLogger.error('Analytics purchase_attempt failed', error: error, stackTrace: stackTrace);
    }
  }
}
