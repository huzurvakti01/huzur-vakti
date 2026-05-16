import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import 'analytics_service.dart';
import 'data_repository_hub.dart';
import 'purchase_service.dart';

class AiClientService {
  AiClientService({
    http.Client? client,
    FirebaseAuth? auth,
    PurchaseService? purchaseService,
    AnalyticsService? analytics,
  })  : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance,
        _purchaseService = purchaseService,
        _analytics = analytics;

  final http.Client _client;
  final FirebaseAuth _auth;
  final PurchaseService? _purchaseService;
  final AnalyticsService? _analytics;

  Uri get _endpoint {
    final raw = dotenv.env['OPENAI_PROXY_CHAT_ENDPOINT'] ?? '';

    if (raw.isEmpty || raw.contains('yourdomain')) {
      throw const AppException(
        'AI servisi yapılandırılmamış. Lütfen OPENAI_PROXY_CHAT_ENDPOINT değerini kontrol edin.',
        code: 'openai_proxy_missing',
      );
    }

    return Uri.parse(raw);
  }

  Future<String> sendMessage({
    required String message,
    required String languageCode,
    String screen = 'ai_chat',
  }) async {
    final trimmed = message.trim();

    if (trimmed.isEmpty) {
      throw const AppException(
        'Mesaj boş olamaz.',
        code: 'ai_message_empty',
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException(
        'AI asistanı kullanmak için giriş yapmalısınız.',
        code: 'auth_required',
      );
    }

    final token = await user.getIdToken(true);

    if (token == null || token.isEmpty) {
      throw const AppException(
        'Oturum doğrulanamadı. Lütfen tekrar giriş yapın.',
        code: 'id_token_missing',
      );
    }

    final premium = _purchaseService?.isPremium ?? false;

    try {
      final response = await _client
          .post(
            _endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
              'X-Huzur-Client': 'mobile',
            },
            body: jsonEncode({
              'message': trimmed,
              'languageCode': languageCode,
              'isPremium': premium,
              'screen': screen,
            }),
          )
          .timeout(const Duration(seconds: 45));

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 429) {
        throw AppException(
          (decoded['message'] ?? 'Çok sık istek gönderildi. Lütfen biraz sonra tekrar deneyin.').toString(),
          code: 'rate_limited',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          (decoded['message'] ?? AppStrings.genericError).toString(),
          code: (decoded['code'] ?? 'ai_proxy_failed').toString(),
        );
      }

      final answer = (decoded['answer'] ?? '').toString().trim();

      if (answer.isEmpty) {
        throw const AppException(
          'AI yanıtı boş döndü. Lütfen tekrar deneyin.',
          code: 'ai_empty_answer',
        );
      }

      await _analytics?.logAiMessage(
        languageCode: languageCode,
        isPremium: premium,
        screen: screen,
      );

      return DataRepositoryHub().appendAiFatwaDisclaimer(answer);
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'AI proxy request failed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'uid': user.uid,
          'languageCode': languageCode,
          'screen': screen,
        },
      );

      throw AppException(
        'AI servisine ulaşılamadı. Bağlantınızı kontrol edip tekrar deneyin.',
        cause: error,
        stackTrace: stackTrace,
        code: 'ai_network_failed',
      );
    }
  }
}
