# App Engine & Brand Controller

Main screen:

```text
admin_panel/lib/screens/god_mode_studio.dart
```

## Modules

### Brand & Logo Editor

- Picks local `.png` with `file_picker`
- Uploads to Firebase Storage under `brand_assets/`
- Writes `logoUrl` and `splashImageUrl` to Firestore:

```text
app_settings/theme
```

- Edits `primaryColor`

### Feature Control Matrix

Publishes these Remote Config flags through Cloud Functions:

```text
isAiEnabled
isWomenCalendarVisible
isSeferiModeActive
isMediaCenterActive
areAdsEnabled
isNativeAdEnabled
isInterstitialEnabled
isPremiumPaywallEnabled
isCommunityEnabled
isKidsModeEnabled
```

### Monetization

Stores and publishes:

```text
admobNativeAndroidId
admobNativeIosId
admobInterstitialAndroidId
admobInterstitialIosId
premiumMonthlyLabel
premiumYearlyLabel
premiumLifetimeLabel
premiumDiscountLabel
```

### Translation Override

Writes 6-language override values to:

```text
app_settings/localization_override
app_settings/theme.localization_override
```

Mobile listens to `app_settings/theme` through:

```text
mobile_app/lib/core/config/app_god_mode_resolver.dart
```
