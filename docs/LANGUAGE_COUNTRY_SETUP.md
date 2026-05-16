# Language & Country Setup

## First Launch

Initial route:

```text
/language-country-setup
```

The app opens a glassmorphism language/country setup screen before auth.

## Language Selection

File:

```text
mobile_app/lib/features/onboarding/presentation/language_country_setup_screen.dart
```

Supported languages:

- Turkish `tr`
- English `en`
- Arabic `ar` — RTL
- French `fr`
- Urdu `ur` — RTL
- Indonesian `id`

Selecting a language calls:

```dart
context.setLocale(locale)
```

Flutter / easy_localization handles RTL for Arabic and Urdu.

## Country Selection

The screen includes:

- Searchable country list
- Flag cards
- Country-specific calculation method labels
- “Konumumu Otomatik Bul” button

GPS detection uses:

```dart
LocationService.currentPosition()
GlobalSettingsService.autoSelectCountry(...)
```

## Calculation Method

Country selection automatically sets the AlAdhan calculation method:

- Turkey → Diyanet
- Saudi Arabia / Gulf countries → Umm Al-Qura
- USA / Canada → ISNA
- Other regions → MWL

## Settings Integration

Settings includes:

```text
Dil ve Ülke Seçimini Aç
```

It opens:

```text
/language-country-setup?edit=1
```

so the setup screen remains accessible after first launch.
