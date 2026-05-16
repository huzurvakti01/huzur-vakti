import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class AdConsentService {
  static const _firstConsentCompleted = 'ad_consent_first_completed_v1';

  Future<void> requestConsentOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_firstConsentCompleted) ?? false;

    if (completed) {
      return;
    }

    try {
      await requestConsentForm();
      await prefs.setBool(_firstConsentCompleted, true);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Initial UMP consent flow failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> requestConsentForm() async {
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (formError != null) {
              AppLogger.warning(
                'UMP consent form failed',
                context: {
                  'code': formError.errorCode,
                  'message': formError.message,
                },
              );
            }
          });
        },
        (formError) {
          AppLogger.warning(
            'UMP consent info update failed',
            context: {
              'code': formError.errorCode,
              'message': formError.message,
            },
          );
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'UMP consent request failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.consentFormUnavailable,
        cause: error,
        stackTrace: stackTrace,
        code: 'ump_consent_failed',
      );
    }
  }

  Future<void> showPrivacyOptions() async {
    try {
      ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          AppLogger.warning(
            'UMP privacy options failed',
            context: {
              'code': formError.errorCode,
              'message': formError.message,
            },
          );
        }
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'UMP privacy options exception',
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
  }

  Future<void> resetConsentForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstConsentCompleted);
    await ConsentInformation.instance.reset();
  }
}
