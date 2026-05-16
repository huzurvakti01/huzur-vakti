import 'package:just_audio/just_audio.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class MediaStreamItem {
  final String id;
  final String title;
  final String subtitle;
  final String url;
  final bool youtube;

  const MediaStreamItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.youtube,
  });
}

class MediaCenterService {
  final AudioPlayer _radio = AudioPlayer();

  static const streams = [
    MediaStreamItem(
      id: 'makkah_live',
      title: AppStrings.liveMakkah,
      subtitle: 'Mekke canlı yayın',
      url: 'https://www.youtube.com/watch?v=f0bbDFRYD_A',
      youtube: true,
    ),
    MediaStreamItem(
      id: 'madinah_live',
      title: AppStrings.liveMadinah,
      subtitle: 'Medine canlı yayın',
      url: 'https://www.youtube.com/watch?v=m3L5A9vZ8W4',
      youtube: true,
    ),
    MediaStreamItem(
      id: 'quran_radio',
      title: AppStrings.quranRadio,
      subtitle: 'Kesintisiz Kur’an tilaveti',
      url: 'https://stream.radiojar.com/8s5u5tpdtwzuv',
      youtube: false,
    ),
  ];

  Future<void> playRadio({
    required String url,
    required bool isPremium,
    bool background = false,
  }) async {
    if (background && !isPremium) {
      throw const AppException(
        AppStrings.backgroundAudioPremiumOnly,
        code: 'premium_required_background_radio',
      );
    }

    try {
      await _radio.setUrl(url);
      await _radio.play();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Quran radio playback failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.genericError,
        cause: error,
        stackTrace: stackTrace,
        code: 'radio_play_failed',
      );
    }
  }

  Future<void> stop() => _radio.stop();

  void dispose() => _radio.dispose();
}
