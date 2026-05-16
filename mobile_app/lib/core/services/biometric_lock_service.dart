import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class BiometricLockService {
  static const _enabledKey = 'premium_biometric_lock_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled({
    required bool value,
    required bool isPremium,
  }) async {
    if (value && !isPremium) {
      throw const AppException(
        AppStrings.biometricLocked,
        code: 'premium_required_biometric',
      );
    }

    if (value) {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (!supported || !canCheck) {
        throw const AppException(
          AppStrings.biometricUnavailable,
          code: 'biometric_unavailable',
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<bool> authenticate() async {
    try {
      final enabled = await isEnabled();

      if (!enabled) return true;

      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (!supported || !canCheck) {
        throw const AppException(
          AppStrings.biometricUnavailable,
          code: 'biometric_unavailable',
        );
      }

      return _auth.authenticate(
        localizedReason: AppStrings.biometricReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logBiometricFailed,
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.biometricFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'biometric_failed',
      );
    }
  }
}
