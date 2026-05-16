# Auto Detect Smart Onboarding

## First Route

The app now starts at:

```text
/smart-setup
```

## Screen

```text
mobile_app/lib/features/onboarding/presentation/smart_setup_screen.dart
```

## Auto Detection

The smart setup screen uses:

- `dart:ui PlatformDispatcher.instance.locale` for device language
- `LocationService.currentPosition()` / Geolocator for GPS country detection
- `CountryProfile.byCoordinates()` for regional country matching
- `GlobalSettingsService.setCountry()` for AlAdhan calculation method setup

## Confirmation Flow

The screen shows:

- Detected region
- Detected language
- LTR / RTL direction indicator
- AlAdhan calculation method

Primary CTA:

```text
Onayla ve Devam Et
```

Secondary CTA:

```text
Bölgeyi/Dili Değiştir
```

## Manual Flow

Manual selection supports:

- Turkish
- English
- Arabic
- French
- Urdu
- Indonesian

Arabic and Urdu use Flutter/easy_localization directionality for RTL.
