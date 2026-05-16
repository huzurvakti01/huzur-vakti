# No Empty Content & Wallpaper Fullness

## Wallpaper Gallery

File:

```text
mobile_app/lib/features/gallery/presentation/wallpaper_gallery_screen.dart
```

Behavior:

- Fetches Unsplash API if `UNSPLASH_ACCESS_KEY` exists.
- Falls back to high-quality `images.unsplash.com` URLs.
- Tapping an image opens actions:
  - Save to device app documents
  - Create greeting card using the selected image as background
  - Share image URL/source

## Greeting Card

Files:

```text
mobile_app/lib/features/tools/presentation/greeting_card_screen.dart
mobile_app/lib/core/services/greeting_card_service.dart
```

The greeting card creator accepts `initialImageUrl` through GoRouter `state.extra` and renders the selected wallpaper as the card background.

## Dashboard Religious Content

File:

```text
mobile_app/lib/core/services/religious_content_service.dart
```

Live sources:

- Ayah: `quran.cloud`
- Hadith: `api.hadith.gading.dev`
- Khutbah: `diyanet.gov.tr`

The dashboard uses the active locale through `easy_localization`.

No-empty guarantee:

- If one source fails, the remaining live sources still render.
- If all sources fail, curated fallback Ayah/Hadith/Dua cards render.
