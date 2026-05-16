import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class AppIconOption {
  final String id;
  final String title;
  final String? iconName;

  const AppIconOption({
    required this.id,
    required this.title,
    required this.iconName,
  });
}

class AppIconService {
  static const _selectedIconKey = 'selected_app_icon';

  static const options = [
    AppIconOption(
      id: 'default',
      title: AppStrings.appIconDefault,
      iconName: null,
    ),
    AppIconOption(
      id: 'gold',
      title: AppStrings.appIconGold,
      iconName: 'GoldIcon',
    ),
    AppIconOption(
      id: 'dark',
      title: AppStrings.appIconDark,
      iconName: 'DarkIcon',
    ),
  ];

  Future<String> selectedIconId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedIconKey) ?? 'default';
  }

  Future<bool> supportsAlternateIcons() async {
    try {
      return await FlutterDynamicIcon.supportsAlternateIcons;
    } catch (error, stackTrace) {
      AppLogger.warning(
        AppStrings.logAppIconChangeFailed,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> changeIcon({
    required AppIconOption option,
    required bool isPremium,
  }) async {
    if (!isPremium) {
      throw const AppException(
        AppStrings.appIconLocked,
        code: 'premium_required_icon_change',
      );
    }

    try {
      final supported = await supportsAlternateIcons();

      if (!supported) {
        throw const AppException(
          AppStrings.appIconUnsupported,
          code: 'alternate_icons_unsupported',
        );
      }

      await FlutterDynamicIcon.setAlternateIconName(
        iconName: option.iconName,
        showAlert: false,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedIconKey, option.id);
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAppIconChangeFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'iconId': option.id},
      );

      throw AppException(
        AppStrings.appIconChangeFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'app_icon_change_failed',
      );
    }
  }
}
