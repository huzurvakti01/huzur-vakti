# Islamic Content Integrity & Offline Fallback

## AI Fatwa Disclaimer

Every AI answer is passed through:

```text
DataRepositoryHub.appendAiFatwaDisclaimer
```

Mandatory disclaimer:

```text
Bu cevap bir yapay zeka asistanı tarafından fıkıh kaynakları taranarak hazırlanmıştır. Bağlayıcı bir fetva niteliği taşımamaktadır. Hassas meselelerde resmi dini kurumlara danışılması tavsiye edilir.
```

## Offline Fallback Assets

```text
mobile_app/assets/json/quran_surahs.json
mobile_app/assets/json/quran_tr.json
mobile_app/assets/json/prayer_fallback.json
mobile_app/assets/json/content_fallback.json
```

## Central Repository

```text
mobile_app/lib/core/services/data_repository_hub.dart
```

Responsibilities:

- Internet probe
- AlAdhan network → local prayer fallback
- quran.cloud network → local Quran fallback
- Local translation fallback
- Local daily Ayah/Hadith/Dua content fallback
- AI disclaimer guard

## Services Using the Hub

```text
mobile_app/lib/core/services/prayer_api_service.dart
mobile_app/lib/core/services/quran_api_service.dart
mobile_app/lib/core/services/religious_content_service.dart
mobile_app/lib/core/services/ai_client_service.dart
mobile_app/lib/core/services/ai_chat_service.dart
```

## Translation QA

Localization assets reviewed for Islamic terminology across:

- Turkish
- English
- Arabic
- French
- Urdu
- Indonesian
