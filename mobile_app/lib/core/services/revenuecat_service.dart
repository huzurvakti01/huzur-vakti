import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import 'premium_secure_storage_service.dart';

class RevenueCatService extends ChangeNotifier {
  RevenueCatService({
    PremiumSecureStorageService? secureStorage,
  }) : _secureStorage = secureStorage ?? PremiumSecureStorageService();

  final PremiumSecureStorageService _secureStorage;

  bool _configured = false;
  bool _isPremium = false;
  CustomerInfo? _customerInfo;
  Offerings? _offerings;

  bool get configured => _configured;
  bool get isPremium => _isPremium;
  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;

  Future<void> init() async {
    final androidKey = dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '';
    final iosKey = dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '';
    final key = defaultTargetPlatform == TargetPlatform.iOS ? iosKey : androidKey;

    if (key.isEmpty || key.contains('your_revenuecat')) {
      AppLogger.warning('RevenueCat key missing');
      return;
    }

    try {
      await Purchases.setLogLevel(kReleaseMode ? LogLevel.warn : LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(key));
      _configured = true;
      await refresh();
    } catch (error, stackTrace) {
      AppLogger.error(
        'RevenueCat initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw AppException(
        AppStrings.revenueCatUnavailable,
        cause: error,
        stackTrace: stackTrace,
        code: 'revenuecat_init_failed',
      );
    }
  }

  Future<void> refresh() async {
    if (!_configured) return;

    try {
      _customerInfo = await Purchases.getCustomerInfo();
      _offerings = await Purchases.getOfferings();
      _isPremium = _customerInfo?.entitlements.active.isNotEmpty ?? false;
      await _persistPremiumState(source: 'refresh');
      notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.error(
        'RevenueCat refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> purchase(Package package) async {
    if (!_configured) {
      throw const AppException(
        AppStrings.revenueCatUnavailable,
        code: 'revenuecat_not_configured',
      );
    }

    try {
      _customerInfo = await Purchases.purchasePackage(package);
      _isPremium = _customerInfo?.entitlements.active.isNotEmpty ?? false;
      await _persistPremiumState(source: 'purchase:${package.identifier}');
      notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.error(
        'RevenueCat purchase failed',
        error: error,
        stackTrace: stackTrace,
        context: {'package': package.identifier},
      );
      throw AppException(
        'Satın alma tamamlanamadı. Lütfen mağaza hesabınızı kontrol edin.',
        cause: error,
        stackTrace: stackTrace,
        code: 'revenuecat_purchase_failed',
      );
    }
  }

  Future<void> restore() async {
    if (!_configured) return;

    try {
      _customerInfo = await Purchases.restorePurchases();
      _isPremium = _customerInfo?.entitlements.active.isNotEmpty ?? false;
      await _persistPremiumState(source: 'restore_receipt_verification');
      notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.error(
        'RevenueCat restore failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw AppException(
        'Satın alma geçmişi geri yüklenemedi.',
        cause: error,
        stackTrace: stackTrace,
        code: 'revenuecat_restore_failed',
      );
    }
  }

  Future<void> _persistPremiumState({required String source}) async {
    final activeEntitlement = _customerInfo?.entitlements.active.keys.firstOrNull ?? 'none';

    await _secureStorage.saveVerifiedPremium(
      isPremium: _isPremium,
      entitlement: activeEntitlement,
      source: source,
    );
  }
}


extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
