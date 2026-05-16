import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class ConsentService {
  Future<void> requestConsent() async {
    final completer = Completer<void>();

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            ConsentForm.loadAndShowConsentFormIfRequired((formError) {
              if (formError != null) {
                AppLogger.warning(
                  'UMP consent form returned error',
                  context: {'code': formError.errorCode, 'message': formError.message},
                );
              }

              if (!completer.isCompleted) completer.complete();
            });
          } catch (error, stackTrace) {
            AppLogger.error(
              'UMP consent form failed',
              error: error,
              stackTrace: stackTrace,
            );
            if (!completer.isCompleted) completer.complete();
          }
        },
        (formError) {
          AppLogger.warning(
            'UMP consent info update failed',
            context: {'code': formError.errorCode, 'message': formError.message},
          );
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'UMP consent request failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {},
    );
  }

  Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();

    try {
      ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          if (!completer.isCompleted) {
            completer.completeError(
              AppException(
                AppStrings.consentFormUnavailable,
                code: 'ump_privacy_options_failed',
              ),
            );
          }
          return;
        }

        if (!completer.isCompleted) completer.complete();
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'UMP privacy options failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.consentFormUnavailable,
        cause: error,
        stackTrace: stackTrace,
        code: 'ump_privacy_options_failed',
      );
    }

    return completer.future;
  }
}
