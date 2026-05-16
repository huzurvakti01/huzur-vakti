# Cloud Sync Free + Premium Guards

## Final Rule

Cloud Sync is free for every signed-in user. It is not a Premium feature.

Signed-in users:

- Google sign-in
- Apple sign-in

get Firestore backup under:

```text
users/{uid}/cloud_sync/ibadah_progress
```

Guest users remain local-only.

## Free Cloud Sync

Files:

- `lib/core/services/auth_service.dart`
- `lib/core/services/cloud_sync_service.dart`
- `lib/core/services/gamification_service.dart`
- `lib/features/auth/presentation/auth_screen.dart`
- `lib/features/profile/presentation/profile_backup_screen.dart`

Provider integration:

```text
ChangeNotifierProxyProvider<AuthService, GamificationService>
```

## Premium-Only Features That Remain Locked

### Sabah Namazı Kalkış Garantisi

Files:

- `lib/core/services/hard_wake_service.dart`
- `lib/features/alarm/presentation/adhan_alarm_screen.dart`
- `lib/features/settings/presentation/settings_screen.dart`

Guard:

```text
HardWakeService.setEnabled(value: true, isPremium: ...)
```

### Biometric Face ID / Touch ID Lock

Files:

- `lib/core/services/biometric_lock_service.dart`
- `lib/features/premium/presentation/secure_notes_screen.dart`
- `lib/features/settings/presentation/settings_screen.dart`

Guard:

```text
BiometricLockService.setEnabled(value: true, isPremium: ...)
SecureNotesScreen checks PurchaseService.isPremium
```

### Premium Audio Library

File:

- `lib/features/premium/presentation/premium_audio_library_screen.dart`

Guard:

```text
PurchaseService.isPremium
```

Free users are redirected to the Premium paywall.
