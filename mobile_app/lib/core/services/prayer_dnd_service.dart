import 'package:flutter_dnd/flutter_dnd.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class PrayerDndService {
  static const _enabled = 'prayer_dnd_enabled';

  Future<bool> hasPolicyAccess() async {
    return await FlutterDnd.isNotificationPolicyAccessGranted ?? false;
  }

  Future<void> openPolicySettings() async {
    await FlutterDnd.gotoPolicySettings();
  }

  Future<bool> ensurePolicyAccess() async {
    final granted = await hasPolicyAccess();

    if (!granted) {
      await openPolicySettings();
      return false;
    }

    return true;
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final granted = await FlutterDnd.isNotificationPolicyAccessGranted ?? false;
      if (!granted) {
        await FlutterDnd.gotoPolicySettings();
        throw const AppException(
          AppStrings.dndPermissionNeeded,
          code: 'dnd_permission_required',
        );
      }
    }

    await prefs.setBool(_enabled, value);
  }

  Future<void> activateForPrayerWindow() async {
    try {
      final granted = await FlutterDnd.isNotificationPolicyAccessGranted ?? false;

      if (!granted) {
         FlutterDnd.gotoPolicySettings();
        throw const AppException(
          AppStrings.dndPermissionNeeded,
          code: 'dnd_permission_required',
        );
      }

      await FlutterDnd.setInterruptionFilter(FlutterDnd.INTERRUPTION_FILTER_PRIORITY);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Prayer DND activation failed',
        error: error,
        stackTrace: stackTrace,
      );

      if (error is AppException) rethrow;

      throw AppException(
        AppStrings.genericError,
        cause: error,
        stackTrace: stackTrace,
        code: 'dnd_activation_failed',
      );
    }
  }

  Future<void> deactivate() async {
    await FlutterDnd.setInterruptionFilter(FlutterDnd.INTERRUPTION_FILTER_ALL);
  }
}
