# Huzur Vakti Global SuperApp

## Mobile

Supported locales:

- Turkish: `tr`
- English: `en`
- Arabic: `ar` — RTL
- French: `fr`
- Urdu: `ur` — RTL
- Indonesian: `id`

Localization package:

```text
easy_localization
```

Translation assets:

```text
mobile_app/assets/translations/tr.json
mobile_app/assets/translations/en.json
mobile_app/assets/translations/ar.json
mobile_app/assets/translations/fr.json
mobile_app/assets/translations/ur.json
mobile_app/assets/translations/id.json
```

## Quran Translation Mapping

`QuranApiService.translationEditionForLocale()`:

- `tr` → `tr.diyanet`
- `en` → `en.sahih`
- `ar` → `ar.muyassar`
- `fr` → `fr.hamidullah`
- `ur` → `ur.jalandhry`
- `id` → `id.indonesian`

## Prayer Calculation Methods

`GlobalSettingsService` supports:

- Diyanet: 13
- MWL: 3
- ISNA: 2
- Umm Al-Qura: 4

`autoSelectCalculationMethod()` selects by GPS region.

## Hijri Calendar

Hijri offset: `-2, -1, 0, +1, +2`.

## Ads Consent

`ConsentService` uses Google UMP:

- `ConsentInformation.instance.requestConsentInfoUpdate`
- `ConsentForm.loadAndShowConsentFormIfRequired`
- `ConsentForm.showPrivacyOptionsForm`

## Admin Panel

The ZIP includes `admin_panel/` as a separate Flutter Web God Mode project with:

- AI moderation
- AI content autopilot
- Remote Config kill switch
- User Matrix
- Support Tickets
