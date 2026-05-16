# Premium-Only Features Upgrade

## Sabah Namazı Kalkış Garantisi

- Package: `sensors_plus`
- Service: `lib/core/services/hard_wake_service.dart`
- Alarm screen: `lib/features/alarm/presentation/adhan_alarm_screen.dart`
- Settings integration: `lib/features/settings/presentation/settings_screen.dart`

Premium users can enable hard wake mode. Supported challenge types:

- Shake phone 20 times
- Solve a math problem

## Biometric Lock

- Package: `local_auth`
- Service: `lib/core/services/biometric_lock_service.dart`
- Secure storage area: `lib/features/premium/presentation/secure_notes_screen.dart`

Premium users can protect private notes and dream entries with Face ID / Touch ID / device authentication.

## Guided Reflection & Podcast Library

- Screen: `lib/features/premium/presentation/premium_audio_library_screen.dart`
- Route: `/premium-library`

Free users are routed to the Premium paywall. Premium users can open the curated content library.

## Premium State

All features are connected to the existing Provider graph and `PurchaseService.isPremium`.
