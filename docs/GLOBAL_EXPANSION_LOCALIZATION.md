# Global Expansion & Localization

## i18n & RTL

The mobile app now uses `easy_localization` with four locales:

- Turkish: `tr`
- English: `en`
- Arabic: `ar`
- French: `fr`

Translation assets:

```text
mobile_app/assets/translations/tr.json
mobile_app/assets/translations/en.json
mobile_app/assets/translations/ar.json
mobile_app/assets/translations/fr.json
```

Arabic uses Flutter localization directionality automatically through `EasyLocalization` and `MaterialApp.router` locale/delegates.

## Global Prayer Calculation

Files:

- `lib/core/models/calculation_method.dart`
- `lib/core/services/global_settings_service.dart`
- `lib/core/services/prayer_api_service.dart`
- `lib/core/state/prayer_controller.dart`

Supported calculation methods:

- Diyanet: 13
- MWL: 3
- ISNA: 2
- Umm Al-Qura: 4

`autoSelectCalculationMethod()` chooses a sensible default from GPS coordinates:

- Turkey → Diyanet
- Arabian Peninsula → Umm Al-Qura
- North America → ISNA
- Elsewhere → MWL

## Quran Translation by Active Language

`QuranApiService.translationEditionForLocale()` maps:

- `tr` → `tr.diyanet`
- `en` → `en.sahih`
- `fr` → `fr.hamidullah`
- `ar` → `ar.muyassar`

## Hijri Offset

Users can adjust the Hijri day by -2, -1, 0, +1, +2.

Stored via `GlobalSettingsService`.

## GDPR/CCPA Ad Consent

`ConsentService` starts Google UMP consent on launch:

```text
ConsentInformation.instance.requestConsentInfoUpdate
ConsentForm.loadAndShowConsentFormIfRequired
```

Settings screen includes a privacy/consent form entry.
