# Dashboard Native Ad

## Widget

File:

```text
lib/widgets/dashboard_native_ad.dart
```

## Home Integration

File:

```text
lib/features/home/presentation/home_screen.dart
```

Placement:

```text
_HeroPrayerCard()
_QuickActions()
DashboardNativeAd()
_PrayerListCard()
```

This places the ad immediately below the dashboard shortcut cards.

## Premium Behavior

The widget watches:

- `PurchaseService.isPremium`
- `AdService.globallyDisabled`

If either is true, it returns:

```dart
SizedBox.shrink()
```

So it occupies zero pixels and lower dashboard content moves up.

## Ad Unit IDs

`AdService.nativeUnitId(context)` reads:

```text
ADMOB_ANDROID_NATIVE_ID
ADMOB_IOS_NATIVE_ID
```

Falls back to official Google Mobile Ads test native ad unit IDs.

## Design

The card uses:

- NativeAd / AdWidget
- NativeTemplateStyle medium template
- Rounded 16px native body
- Glass-style outer container
- Emerald CTA button
- Sponsored chip
