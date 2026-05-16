import 'package:just_audio/just_audio.dart';

import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class QuranAudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playUrl(String url) async {
    if (url.isEmpty) {
      throw const AppException('Ses bağlantısı bulunamadı.', code: 'quran_audio_url_empty');
    }

    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Quran audio playback failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw AppException(
        'Sesli okuma başlatılamadı.',
        cause: error,
        stackTrace: stackTrace,
        code: 'quran_audio_play_failed',
      );
    }
  }

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}
