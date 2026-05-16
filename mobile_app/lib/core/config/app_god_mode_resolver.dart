import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../logging/app_logger.dart';

class GodModeThemeSnapshot {
  final String logoUrl;
  final String splashImageUrl;
  final Color primaryColor;
  final Map<String, String> localizationOverride;
  final DateTime updatedAt;

  const GodModeThemeSnapshot({
    required this.logoUrl,
    required this.splashImageUrl,
    required this.primaryColor,
    required this.localizationOverride,
    required this.updatedAt,
  });

  factory GodModeThemeSnapshot.fallback() {
    return GodModeThemeSnapshot(
      logoUrl: '',
      splashImageUrl: '',
      primaryColor: const Color(0xFF0E7C66),
      localizationOverride: const {},
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory GodModeThemeSnapshot.fromFirestore(Map<String, dynamic> data) {
    return GodModeThemeSnapshot(
      logoUrl: (data['logoUrl'] ?? '').toString().trim(),
      splashImageUrl: (data['splashImageUrl'] ?? '').toString().trim(),
      primaryColor: _parseColor((data['primaryColor'] ?? '#0E7C66').toString()),
      localizationOverride: _parseLocalization(data['localization_override']),
      updatedAt: DateTime.now(),
    );
  }

  static Color _parseColor(String value) {
    final clean = value.replaceAll('#', '').trim();
    final normalized = clean.length == 6 ? 'FF$clean' : clean;

    if (normalized.length != 8) {
      return const Color(0xFF0E7C66);
    }

    return Color(int.parse(normalized, radix: 16));
  }

  static Map<String, String> _parseLocalization(dynamic raw) {
    if (raw is! Map) return const {};

    return raw.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
}

class GodModeFeatureFlags {
  final bool isAiEnabled;
  final bool isWomenCalendarVisible;
  final bool isSeferiModeActive;
  final bool isMediaCenterActive;

  const GodModeFeatureFlags({
    required this.isAiEnabled,
    required this.isWomenCalendarVisible,
    required this.isSeferiModeActive,
    required this.isMediaCenterActive,
  });

  factory GodModeFeatureFlags.defaults() {
    return const GodModeFeatureFlags(
      isAiEnabled: true,
      isWomenCalendarVisible: true,
      isSeferiModeActive: true,
      isMediaCenterActive: true,
    );
  }

  factory GodModeFeatureFlags.fromRemoteConfig(FirebaseRemoteConfig remoteConfig) {
    return GodModeFeatureFlags(
      isAiEnabled: remoteConfig.getBool('isAiEnabled'),
      isWomenCalendarVisible: remoteConfig.getBool('isWomenCalendarVisible'),
      isSeferiModeActive: remoteConfig.getBool('isSeferiModeActive'),
      isMediaCenterActive: remoteConfig.getBool('isMediaCenterActive'),
    );
  }

  bool routeEnabled(String path) {
    if (path == '/ai') return isAiEnabled;
    if (path == '/women-calendar') return isWomenCalendarVisible;
    if (path == '/traveler') return isSeferiModeActive;
    if (path == '/media-center') return isMediaCenterActive;
    return true;
  }
}

class AppGodModeResolver extends ChangeNotifier {
  AppGodModeResolver({
    FirebaseFirestore? firestore,
    FirebaseRemoteConfig? remoteConfig,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseFirestore _firestore;
  final FirebaseRemoteConfig _remoteConfig;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _themeSub;
  GodModeThemeSnapshot _theme = GodModeThemeSnapshot.fallback();
  GodModeFeatureFlags _flags = GodModeFeatureFlags.defaults();
  bool _initialized = false;

  GodModeThemeSnapshot get theme => _theme;
  GodModeFeatureFlags get flags => _flags;
  bool get initialized => _initialized;
  String get logoUrl => _theme.logoUrl;
  String get splashImageUrl => _theme.splashImageUrl;
  Color get primaryColor => _theme.primaryColor;

  Future<void> init() async {
    await _initRemoteConfig();
    _listenThemeDocument();

    _initialized = true;
    notifyListeners();
  }

  Future<void> _initRemoteConfig() async {
    try {
      await _remoteConfig.setDefaults({
        'isAiEnabled': true,
        'isWomenCalendarVisible': true,
        'isSeferiModeActive': true,
        'isMediaCenterActive': true,
      });

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 12),
          minimumFetchInterval: const Duration(seconds: 30),
        ),
      );

      await _remoteConfig.fetchAndActivate();
      _flags = GodModeFeatureFlags.fromRemoteConfig(_remoteConfig);

      _remoteConfig.onConfigUpdated.listen((event) async {
        try {
          await _remoteConfig.activate();
          _flags = GodModeFeatureFlags.fromRemoteConfig(_remoteConfig);
          notifyListeners();
        } catch (error, stackTrace) {
          AppLogger.error(
            'Remote Config live activation failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Remote Config init failed; default flags will be used',
        error: error,
        stackTrace: stackTrace,
      );
      _flags = GodModeFeatureFlags.defaults();
    }
  }

  void _listenThemeDocument() {
    _themeSub?.cancel();
    _themeSub = _firestore.doc('app_settings/theme').snapshots().listen(
      (snapshot) {
        final data = snapshot.data();

        if (data == null || data.isEmpty) {
          _theme = GodModeThemeSnapshot.fallback();
        } else {
          _theme = GodModeThemeSnapshot.fromFirestore(data);
        }

        notifyListeners();
      },
      onError: (error, stackTrace) {
        AppLogger.error(
          'Firestore app_settings/theme listener failed',
          error: error,
          stackTrace: stackTrace is StackTrace ? stackTrace : StackTrace.current,
        );

        _theme = GodModeThemeSnapshot.fallback();
        notifyListeners();
      },
    );
  }

  String text(String key, String fallback) {
    final value = _theme.localizationOverride[key];

    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    return value;
  }

  bool isFeatureVisible(String key) {
    switch (key) {
      case 'ai':
        return _flags.isAiEnabled;
      case 'women_calendar':
        return _flags.isWomenCalendarVisible;
      case 'seferi':
      case 'traveler':
        return _flags.isSeferiModeActive;
      case 'media_center':
        return _flags.isMediaCenterActive;
      default:
        return true;
    }
  }

  ThemeData applyDynamicTheme(ThemeData base) {
    final scheme = base.colorScheme.copyWith(
      primary: primaryColor,
      secondary: const Color(0xFFE2B659),
    );

    return base.copyWith(
      colorScheme: scheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _themeSub?.cancel();
    super.dispose();
  }
}
