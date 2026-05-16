import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_strings.dart';
import '../../errors/app_exception.dart';
import '../../logging/app_logger.dart';
import '../../models/adhan_audio_source.dart';

class AdhanAudioService {
  static const selectedKey = 'selected_adhan_audio_source';
  static const fallbackAsset = 'assets/audio/fallback.mp3';
  static const _downloadedPrefix = 'downloaded_adhan_';

  final AudioPlayer _player = AudioPlayer();

  static const sources = [
    AdhanAudioSource(
      id: 'makkah_sudais',
      title: 'Mekke İmamı (Sudeysi)',
      subtitle: 'Mekke tarzı güçlü ezan',
      url: 'https://cdn.aladhan.com/audio/adhans/MisharyRashidAlafasy.mp3',
      cacheEnabled: true,
    ),
    AdhanAudioSource(
      id: 'madinah',
      title: 'Medine İmamı',
      subtitle: 'Sakin ve klasik ezan',
      url: 'https://cdn.aladhan.com/audio/adhans/adhan_madina.mp3',
      cacheEnabled: true,
    ),
    AdhanAudioSource(
      id: 'turkey_diyanet',
      title: 'Türkiye Diyanet Stili',
      subtitle: 'Türkiye makamına yakın ton',
      url: 'https://cdn.aladhan.com/audio/adhans/HafizMustafaOzcan.mp3',
      cacheEnabled: true,
    ),
    AdhanAudioSource(
      id: 'fallback',
      title: 'Kısa Uyarı Sesi',
      subtitle: 'İnternet yoksa küçük yedek ses',
      url: '',
      cacheEnabled: false,
    ),
  ];

  Future<AdhanAudioSource> selectedSource() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(selectedKey);
    return sources.firstWhere(
      (item) => item.id == id,
      orElse: () => sources.first,
    );
  }

  Future<void> select(AdhanAudioSource source) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(selectedKey, source.id);
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAdhanSelectionFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'sourceId': source.id},
      );
      throw AppException(
        'Ezan sesi seçimi kaydedilemedi.',
        cause: error,
        stackTrace: stackTrace,
        code: 'adhan_source_save_failed',
      );
    }
  }

  Future<File?> downloadedFile(AdhanAudioSource source) async {
    if (source.url.isEmpty) return null;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_downloadedPrefix${source.id}.mp3');

    if (await file.exists() && await file.length() > 0) {
      return file;
    }

    return null;
  }

  Future<bool> isDownloaded(AdhanAudioSource source) async {
    return (await downloadedFile(source)) != null;
  }

  Future<File> downloadForPremium({
    required AdhanAudioSource source,
    required bool isPremium,
  }) async {
    if (!isPremium) {
      throw const AppException(
        AppStrings.premiumAdhanDownloadLocked,
        code: 'premium_required_adhan_download',
      );
    }

    if (source.url.isEmpty) {
      throw const AppException(
        AppStrings.adhanDownloadFailed,
        code: 'adhan_source_not_downloadable',
      );
    }

    try {
      final existing = await downloadedFile(source);
      if (existing != null) return existing;

      final response = await http.get(Uri.parse(source.url)).timeout(const Duration(seconds: 40));

      if (response.statusCode < 200 || response.statusCode >= 300 || response.bodyBytes.isEmpty) {
        throw AppException(
          AppStrings.adhanDownloadFailed,
          code: 'adhan_download_status_${response.statusCode}',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_downloadedPrefix${source.id}.mp3');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file;
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAdhanDownloadFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'sourceId': source.id},
      );

      if (error is AppException) rethrow;

      throw AppException(
        AppStrings.adhanDownloadFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'adhan_download_failed',
      );
    }
  }

  Future<void> playSelected({bool loop = true}) async {
    final source = await selectedSource();
    await _player.stop();
    await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);

    if (source.url.isEmpty) {
      await _playFallback();
      return;
    }

    try {
      final downloaded = await downloadedFile(source);

      if (downloaded != null) {
        await _player.setFilePath(downloaded.path);
        await _player.play();
        return;
      }

      final audio = source.cacheEnabled
          ? LockCachingAudioSource(Uri.parse(source.url))
          : AudioSource.uri(Uri.parse(source.url));
      await _player.setAudioSource(audio);
      await _player.play();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Remote adhan audio failed, using fallback',
        error: error,
        stackTrace: stackTrace,
        context: {'sourceId': source.id},
      );
      await _playFallback();
    }
  }

  Future<void> preview(AdhanAudioSource source) async {
    try {
      await select(source);
      HapticFeedback.selectionClick();
      await playSelected(loop: false);
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAdhanPreviewFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'sourceId': source.id},
      );
      rethrow;
    }
  }

  Future<void> stop() => _player.stop();

  Future<void> _playFallback() async {
    try {
      await _player.setAudioSource(AudioSource.asset(fallbackAsset));
      await _player.play();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Fallback adhan audio failed',
        error: error,
        stackTrace: stackTrace,
      );
      HapticFeedback.heavyImpact();
    }
  }

  void dispose() => _player.dispose();
}
