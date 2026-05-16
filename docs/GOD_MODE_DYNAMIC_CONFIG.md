# God Mode Dynamic Config

## Firestore Theme Document

Path:

```text
app_settings/theme
```

Supported fields:

```json
{
  "logoUrl": "https://cdn.example.com/logo.png",
  "splashImageUrl": "https://cdn.example.com/splash.png",
  "primaryColor": "#0E7C66",
  "localization_override": {
    "onboardingTitle": "Yeni canlı başlık",
    "dashboardStoriesTitle": "Bugünün Mesajı"
  }
}
```

If Firestore is unavailable or fields are empty, app falls back to:

```text
assets/images/logo_main.png
```

## Remote Config Feature Flags

Required keys:

```text
isAiEnabled
isWomenCalendarVisible
isSeferiModeActive
isMediaCenterActive
```

The app listens to Remote Config live updates and updates visible modules without requiring an app update.

## Main Service

```text
mobile_app/lib/core/config/app_god_mode_resolver.dart
```

Responsibilities:

- Listen to Firestore `app_settings/theme`
- Fetch and activate Remote Config flags
- React to Remote Config `onConfigUpdated`
- Expose `logoUrl`, `splashImageUrl`, `primaryColor`
- Expose `localization_override`
- Apply dynamic ThemeData primary color
- Hide disabled modules and guard disabled routes

## Dynamic Widgets

```text
mobile_app/lib/shared/widgets/dynamic_brand_logo.dart
mobile_app/lib/shared/widgets/dynamic_splash_image.dart
mobile_app/lib/shared/widgets/god_mode_text.dart
```
