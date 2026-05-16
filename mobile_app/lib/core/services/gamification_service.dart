import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../logging/app_logger.dart';
import '../models/qaza_progress.dart';
import 'cloud_sync_service.dart';

class GamificationService extends ChangeNotifier {
  GamificationService({
    required CloudSyncService cloudSyncService,
  }) : _cloudSyncService = cloudSyncService;

  static const _prefix = 'gamification_';

  final CloudSyncService _cloudSyncService;
  Timer? _syncDebounce;
  User? _user;
  bool _cloudSyncing = false;
  DateTime? _lastCloudSyncAt;

  QazaProgress _progress = QazaProgress(
    qazaCounts: const {
      AppStrings.prayerFajr: 0,
      AppStrings.prayerDhuhr: 0,
      AppStrings.prayerAsr: 0,
      AppStrings.prayerMaghrib: 0,
      AppStrings.prayerIsha: 0,
    },
    quranPagesToday: 0,
    dhikrToday: 0,
    dailyQuranPageTarget: 5,
    dailyDhikrTarget: 100,
    streakDays: 0,
    lastActivityDate: null,
    updatedAt: DateTime.now(),
  );

  QazaProgress get progress => _progress;
  bool get cloudSyncing => _cloudSyncing;
  DateTime? get lastCloudSyncAt => _lastCloudSyncAt;
  bool get cloudSyncAvailable => _user != null && !(_user?.isAnonymous ?? true);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final counts = <String, int>{};

      for (final key in _progress.qazaCounts.keys) {
        counts[key] = prefs.getInt('$_prefix${key}_qaza') ?? 0;
      }

      _progress = QazaProgress(
        qazaCounts: counts,
        quranPagesToday: prefs.getInt('${_prefix}quran_pages_today') ?? 0,
        dhikrToday: prefs.getInt('${_prefix}dhikr_today') ?? 0,
        dailyQuranPageTarget: prefs.getInt('${_prefix}quran_target') ?? 5,
        dailyDhikrTarget: prefs.getInt('${_prefix}dhikr_target') ?? 100,
        streakDays: prefs.getInt('${_prefix}streak_days') ?? 0,
        lastActivityDate: _parseDate(prefs.getString('${_prefix}last_activity_date')),
        updatedAt: _parseDate(prefs.getString('${_prefix}updated_at')) ?? DateTime.now(),
      );

      notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Gamification progress load failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> syncAuthState(User? user) async {
    final previousUid = _user?.uid;
    _user = user;

    if (!cloudSyncAvailable) {
      _syncDebounce?.cancel();
      notifyListeners();
      return;
    }

    if (previousUid != user?.uid) {
      await restoreFromCloudIfNewer();
      _scheduleCloudBackup();
    }
  }

  Future<void> restoreFromCloudIfNewer() async {
    if (!cloudSyncAvailable) return;

    _cloudSyncing = true;
    notifyListeners();

    try {
      final cloud = await _cloudSyncService.restoreProgress(user: _user);

      if (cloud != null && cloud.updatedAt.isAfter(_progress.updatedAt)) {
        _progress = _normalizeProgress(cloud);
        await _persistLocal();
      }

      _lastCloudSyncAt = DateTime.now();
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logCloudRestoreFailed,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _cloudSyncing = false;
      notifyListeners();
    }
  }

  Future<void> backupNow() async {
    if (!cloudSyncAvailable) return;

    _cloudSyncing = true;
    notifyListeners();

    try {
      await _cloudSyncService.backupProgress(
        progress: _progress,
        user: _user,
      );
      _lastCloudSyncAt = DateTime.now();
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logCloudBackupFailed,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _cloudSyncing = false;
      notifyListeners();
    }
  }

  Future<void> setQazaCount(String prayerName, int value) async {
    final safeValue = value < 0 ? 0 : value;
    final counts = Map<String, int>.from(_progress.qazaCounts);
    counts[prayerName] = safeValue;

    _progress = _progress.copyWith(
      qazaCounts: counts,
      updatedAt: DateTime.now(),
    );

    _touchStreak();
    await _persistLocal();
    notifyListeners();
    _scheduleCloudBackup();
  }

  Future<void> addQuranPage() async {
    _progress = _progress.copyWith(
      quranPagesToday: _progress.quranPagesToday + 1,
      updatedAt: DateTime.now(),
    );

    _touchStreak();
    await _persistLocal();
    notifyListeners();
    _scheduleCloudBackup();
  }

  Future<void> addDhikr({int amount = 1}) async {
    _progress = _progress.copyWith(
      dhikrToday: _progress.dhikrToday + amount,
      updatedAt: DateTime.now(),
    );

    _touchStreak();
    await _persistLocal();
    notifyListeners();
    _scheduleCloudBackup();
  }

  void _touchStreak() {
    final today = _dateOnly(DateTime.now());
    final last = _progress.lastActivityDate == null ? null : _dateOnly(_progress.lastActivityDate!);

    if (last == today) return;

    final yesterday = today.subtract(const Duration(days: 1));
    final nextStreak = last == yesterday ? _progress.streakDays + 1 : 1;

    _progress = _progress.copyWith(
      streakDays: nextStreak,
      lastActivityDate: today,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in _progress.qazaCounts.entries) {
      await prefs.setInt('$_prefix${entry.key}_qaza', entry.value);
    }

    await prefs.setInt('${_prefix}quran_pages_today', _progress.quranPagesToday);
    await prefs.setInt('${_prefix}dhikr_today', _progress.dhikrToday);
    await prefs.setInt('${_prefix}quran_target', _progress.dailyQuranPageTarget);
    await prefs.setInt('${_prefix}dhikr_target', _progress.dailyDhikrTarget);
    await prefs.setInt('${_prefix}streak_days', _progress.streakDays);

    if (_progress.lastActivityDate != null) {
      await prefs.setString('${_prefix}last_activity_date', _progress.lastActivityDate!.toIso8601String());
    }

    await prefs.setString('${_prefix}updated_at', _progress.updatedAt.toIso8601String());
  }

  void _scheduleCloudBackup() {
    if (!cloudSyncAvailable) return;

    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 4), backupNow);
  }

  QazaProgress _normalizeProgress(QazaProgress progress) {
    final counts = <String, int>{};

    for (final key in _progress.qazaCounts.keys) {
      counts[key] = progress.qazaCounts[key] ?? 0;
    }

    return progress.copyWith(qazaCounts: counts);
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }
}
