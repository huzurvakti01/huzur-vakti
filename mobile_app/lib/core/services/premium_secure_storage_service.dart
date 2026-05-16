import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logging/app_logger.dart';

class PremiumSecureStorageService {
  PremiumSecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
        );

  final FlutterSecureStorage _storage;

  static const _isPremium = 'premium.is_active';
  static const _entitlement = 'premium.entitlement';
  static const _verifiedAt = 'premium.verified_at';
  static const _source = 'premium.source';

  Future<void> saveVerifiedPremium({
    required bool isPremium,
    required String entitlement,
    required String source,
  }) async {
    try {
      await _storage.write(key: _isPremium, value: isPremium ? '1' : '0');
      await _storage.write(key: _entitlement, value: entitlement);
      await _storage.write(key: _verifiedAt, value: DateTime.now().toUtc().toIso8601String());
      await _storage.write(key: _source, value: source);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Premium secure storage write failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> readCachedPremium() async {
    try {
      return await _storage.read(key: _isPremium) == '1';
    } catch (error, stackTrace) {
      AppLogger.error(
        'Premium secure storage read failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _isPremium);
      await _storage.delete(key: _entitlement);
      await _storage.delete(key: _verifiedAt);
      await _storage.delete(key: _source);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Premium secure storage clear failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
