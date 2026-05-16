# Premium Monetization Upgrade

## AI Daily Limit

- Service: `lib/core/services/ai_chat_service.dart`
- Screen: `lib/features/ai/presentation/ai_chat_screen.dart`
- Free users: 3 messages per day.
- Premium users: unlimited.
- Counter storage: `SharedPreferences`.
- Limit reached: Premium paywall dialog.

## Premium Adhan Download

- Service: `lib/core/services/audio/adhan_audio_service.dart`
- Screen: `lib/features/settings/presentation/settings_screen.dart`
- Premium users can download selected MP3 adhan audio to app documents directory.
- Playback checks local file first, then remote stream/cache, then fallback asset.

## Premium App Icon

- Service: `lib/core/services/app_icon_service.dart`
- Screen: `lib/features/premium/presentation/app_icon_screen.dart`
- Route: `/app-icon`
- Package: `flutter_dynamic_icon`
- iOS alternate icon names:
  - `GoldIcon`
  - `DarkIcon`

Notes:
- Alternate icons require final Xcode validation and complete icon asset sizes before App Store upload.
- Android support depends on launcher/device behavior of `flutter_dynamic_icon`.
