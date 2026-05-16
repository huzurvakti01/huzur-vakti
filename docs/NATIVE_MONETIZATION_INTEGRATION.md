# Native Monetization Integration

## Android NativeAdFactory

Main file:

```text
mobile_app/android/app/src/main/kotlin/com/huzurvakti/app/MainActivity.kt
```

Native layout:

```text
mobile_app/android/app/src/main/res/layout/native_ad_glass.xml
mobile_app/android/app/src/main/res/drawable/native_ad_glass_background.xml
mobile_app/android/app/src/main/res/drawable/native_ad_cta_background.xml
```

Factory ID:

```text
huzur_glass_native
```

## iOS NativeAdFactory

Files:

```text
mobile_app/ios/Runner/AppDelegate.swift
mobile_app/ios/Runner/HuzurGlassNativeAdFactory.swift
```

Factory ID:

```text
huzur_glass_native
```

## RevenueCat / Secure Storage

Files:

```text
mobile_app/lib/core/services/premium_secure_storage_service.dart
mobile_app/lib/core/services/revenuecat_service.dart
mobile_app/lib/core/services/purchase_service.dart
```

The verified premium entitlement state is cached in encrypted secure storage after:

- RevenueCat refresh
- RevenueCat purchase
- RevenueCat restore / receipt verification
- Legacy in_app_purchase purchase/restore stream

## Account Deletion

Files:

```text
mobile_app/lib/core/services/auth_service.dart
mobile_app/lib/features/settings/presentation/settings_screen.dart
```

Settings includes “Hesabımı Sil”. Firebase Auth account deletion is called through `AuthService.deleteAccount()`.

## UMP First Launch Consent

File:

```text
mobile_app/lib/core/services/ad_consent_service.dart
```

`main.dart` starts the first-launch UMP flow through:

```text
AdConsentService.requestConsentOnFirstLaunch
```
