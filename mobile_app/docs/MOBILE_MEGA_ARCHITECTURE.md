# Huzur Vakti Mobile Mega Architecture

## Klasör Yapısı

```text
lib/core
lib/features
lib/shared
```

## Başlatma Akışı

`main.dart` içinde sırasıyla:

1. dotenv
2. Firebase
3. MobileAds
4. Local Notifications
5. Widget Bridge
6. Provider dependency graph
7. go_router

## Hassas Reklam Kuralları

Interstitial yasak ekranlar:

```text
home, prayer, quran, quran_reader, qibla, ai, kids, kids_mode, child_mode,
adhan_alarm, adhan_ringing, tahajjud_sleep
```

Çocuk Modu aktifken tüm reklam altyapısı global olarak kapanır.

## Native Widgetlar

Android:

```text
android/app/src/main/kotlin/com/huzurvakti/app/HuzurPrayerWidget.kt
```

iOS:

```text
ios/HuzurPrayerWidget/HuzurPrayerWidget.swift
ios/HuzurLiveActivity/
```

## Yayın Öncesi

- `flutterfire configure`
- Firebase gerçek ayarları
- AdMob gerçek app/unit ID'leri
- In-App Purchase ürünleri
- Google Maps/Places API keys
- iOS signing/capabilities
- Android signing
