import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_constants.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import 'premium_secure_storage_service.dart';

class PurchaseService extends ChangeNotifier {
  PurchaseService({
    PremiumSecureStorageService? secureStorage,
  }) : _secureStorage = secureStorage ?? PremiumSecureStorageService();

  final PremiumSecureStorageService _secureStorage;
  final InAppPurchase _iap = InAppPurchase.instance;
  final Set<String> _ids = {
    AppConstants.premiumMonthly,
    AppConstants.premiumYearly,
    AppConstants.premiumLifetime,
  };

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _available = false;
  bool _isPremium = false;
  bool _loading = false;
  String? _error;

  List<ProductDetails> get products => _products;
  bool get available => _available;
  bool get isPremium => _isPremium;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _available = await _iap.isAvailable();
      _subscription = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object error, StackTrace stackTrace) {
          AppLogger.error(
            'Purchase stream failed',
            error: error,
            stackTrace: stackTrace,
          );
          _error = 'Satın alma servisine ulaşılamadı.';
          notifyListeners();
        },
      );

      if (_available) {
        final response = await _iap.queryProductDetails(_ids);
        _products = response.productDetails;

        if (response.notFoundIDs.isNotEmpty) {
          AppLogger.warning(
            'IAP products not found',
            context: {'ids': response.notFoundIDs.join(',')},
          );
        }
      } else {
        _error = 'Mağaza satın alma servisi bu cihazda kullanılamıyor.';
        AppLogger.warning('In-app purchase service unavailable');
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Purchase service init failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = 'Satın alma bilgileri alınamadı. Lütfen tekrar deneyin.';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> buy(ProductDetails product) async {
    try {
      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Purchase request failed',
        error: error,
        stackTrace: stackTrace,
        context: {'productId': product.id},
      );
      throw StoreAppException(
        'Satın alma başlatılamadı. Lütfen mağaza hesabınızı kontrol edin.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Purchase restore failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw StoreAppException(
        'Satın alma geçmişi geri yüklenemedi. Lütfen mağaza hesabınızı kontrol edin.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> reloadProducts() => init();

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.error) {
        AppLogger.error(
          'Purchase failed',
          error: purchase.error,
          context: {'productId': purchase.productID},
        );
        _error = 'Satın alma tamamlanamadı. Lütfen tekrar deneyin.';
      }

      if (_ids.contains(purchase.productID) &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        _isPremium = true;
        _error = null;
        _secureStorage.saveVerifiedPremium(
          isPremium: true,
          entitlement: 'premium',
          source: '${purchase.status.name}:${purchase.productID}',
        );
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
