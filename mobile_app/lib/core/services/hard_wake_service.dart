import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

enum HardWakeChallengeMode {
  shake,
  math,
}

class HardWakeMathChallenge {
  final int a;
  final int b;

  const HardWakeMathChallenge({
    required this.a,
    required this.b,
  });

  int get answer => a + b;
}

class HardWakeService extends ChangeNotifier {
  static const _enabledKey = 'premium_hard_wake_enabled';
  static const _modeKey = 'premium_hard_wake_mode';
  static const int requiredShakeCount = 20;

  bool _enabled = false;
  HardWakeChallengeMode _mode = HardWakeChallengeMode.shake;
  int _shakeCount = 0;
  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  bool get enabled => _enabled;
  HardWakeChallengeMode get mode => _mode;
  int get shakeCount => _shakeCount;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    final modeName = prefs.getString(_modeKey);
    _mode = HardWakeChallengeMode.values.firstWhere(
      (item) => item.name == modeName,
      orElse: () => HardWakeChallengeMode.shake,
    );
    notifyListeners();
  }

  Future<void> setEnabled({
    required bool value,
    required bool isPremium,
  }) async {
    if (value && !isPremium) {
      throw const AppException(
        AppStrings.hardWakeLocked,
        code: 'premium_required_hard_wake',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    _enabled = value;
    notifyListeners();
  }

  Future<void> setMode(HardWakeChallengeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
    _mode = mode;
    notifyListeners();
  }

  HardWakeMathChallenge newMathChallenge() {
    final random = Random.secure();
    return HardWakeMathChallenge(
      a: random.nextInt(41) + 10,
      b: random.nextInt(41) + 10,
    );
  }

  void startShakeChallenge({
    required VoidCallback onCompleted,
  }) {
    stopShakeChallenge();
    _shakeCount = 0;
    notifyListeners();

    _sub = accelerometerEventStream().listen(
      (event) {
        final g = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        final now = DateTime.now();

        if (g < 18) return;
        if (now.difference(_lastShake).inMilliseconds < 350) return;

        _lastShake = now;
        _shakeCount++;
        notifyListeners();

        if (_shakeCount >= requiredShakeCount) {
          stopShakeChallenge();
          onCompleted();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          AppStrings.logHardWakeFailed,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  void stopShakeChallenge() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    stopShakeChallenge();
    super.dispose();
  }
}
