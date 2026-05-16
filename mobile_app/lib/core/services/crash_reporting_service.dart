import 'dart:async';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

class CrashReportingService {
  CrashReportingService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  Future<void> init() async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _crashlytics.recordFlutterFatalError(details);
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        _crashlytics.recordError(error, stackTrace, fatal: true);
        return true;
      };
    } catch (error, stackTrace) {
      AppLogger.error(
        'CrashReportingService init failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
    Map<String, Object?> context = const {},
  }) async {
    try {
      for (final entry in context.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value?.toString() ?? 'null');
      }

      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );
    } catch (innerError, innerStackTrace) {
      AppLogger.error(
        'Crashlytics recordError failed',
        error: innerError,
        stackTrace: innerStackTrace,
      );
    }
  }

  Future<void> setUserId(String uid) async {
    try {
      await _crashlytics.setUserIdentifier(uid);
    } catch (error, stackTrace) {
      AppLogger.error('Crashlytics setUserId failed', error: error, stackTrace: stackTrace);
    }
  }
}
