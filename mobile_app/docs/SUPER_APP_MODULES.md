# Huzur Vakti Super App Modules

## Navigation

Main shell now uses four primary bottom tabs:

- Vakit
- Huzur Vakti Super Hub
- Sosyal
- Araçlar

The Super Hub organizes features into internal tabs:

- İbadet
- Kur’an
- Sosyal
- Araçlar

## Added Modules

### Media Center

Files:

- `lib/features/media/presentation/media_center_screen.dart`
- `lib/core/services/media_center_service.dart`

Uses:

- `youtube_player_flutter`
- `just_audio`

Ad rule:

- No banner/interstitial while live stream or radio playback screen is active.
- `media_center`, `quran_radio`, `live_stream` are marked as sensitive no-interstitial screens.

### Women Calendar

Files:

- `lib/features/women/presentation/women_calendar_screen.dart`
- `lib/core/services/women_calendar_service.dart`

Uses:

- `hive`
- `hive_flutter`

Function:

- Tracks menstrual calendar locally.
- Indicates when worship reminders and qaza debt calculation should pause.

### Prayer DND

Files:

- `lib/features/tools/presentation/prayer_dnd_screen.dart`
- `lib/core/services/prayer_dnd_service.dart`

Uses:

- `flutter_dnd`

Function:

- Requests notification policy access.
- Can activate DND/vibration prayer window.

### Greeting Card Creator

Files:

- `lib/features/tools/presentation/greeting_card_screen.dart`
- `lib/core/services/greeting_card_service.dart`

Uses:

- `image`
- `share_plus`

Function:

- Creates shareable PNG greeting cards.

### Khutbah & Moon Phase

Files:

- `lib/features/quran_tools/presentation/khutbah_moon_screen.dart`
- `lib/core/services/khutbah_service.dart`

Function:

- Fetches Diyanet hutbah page.
- Calculates moon phase locally.

### Ayah Finder

Files:

- `lib/features/quran_tools/presentation/ayah_finder_screen.dart`
- `lib/core/services/ayah_finder_service.dart`

Uses:

- `record`
- `permission_handler`

Function:

- Records microphone audio.
- Uploads audio to backend endpoint configured by `AYAH_FINDER_ENDPOINT`.

## Ad Architecture

List/menu screens use:

- `SafeBannerAd`
- `AdService.trackNavigation`
- `AdService.trackButtonTap`

Sensitive playback screens stay ad-free:

- `media_center`
- `quran_radio`
- `live_stream`
