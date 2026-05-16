# Backup Screen Ad Monetization

## Rule

Cloud Sync is free. Therefore the Profile / Backup screen can show ads for free users.

## Banner

Screen:

- `lib/features/profile/presentation/profile_backup_screen.dart`

Banner:

```text
SafeBannerAd(screenKey: profile_backup)
```

Premium users do not see the banner because `SafeBannerAd` checks `PurchaseService.isPremium` through `AdService`.

## Interstitial Trigger

After successful completion of:

- `Şimdi Yedekle`
- Google sign-in
- Apple sign-in
- Guest sign-in from auth screen

the app calls:

```text
AdService.trackCompletedAction(...)
```

This respects:

- `isPremium == true` → no ad
- Kids mode → no ad
- Sensitive screens → no interstitial
- AdService frequency counter

## Route

```text
/profile-backup
```

Settings screen includes a Profile / Backup entry.
