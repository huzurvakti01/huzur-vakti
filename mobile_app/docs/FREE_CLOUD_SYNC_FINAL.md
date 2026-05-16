# Free Cloud Sync Final

## Rule

Cloud Sync is free for every signed-in user. It is not tied to Premium.

## Sign-in

Google and Apple sign-in are handled by:

- `lib/core/services/auth_service.dart`
- `lib/features/auth/presentation/auth_screen.dart`

Guest users can use the app locally, but Firestore backup requires Google/Apple sign-in.

## Synced Data

- Dhikr count
- Qaza prayer counts
- Quran page progress
- Daily streak

## Firestore Path

```text
users/{uid}/cloud_sync/ibadah_progress
```

## Automatic Sync

`GamificationService` receives `AuthService.user` through Provider:

```text
ChangeNotifierProxyProvider<AuthService, GamificationService>
```

When a signed-in user is available:

- App restores newer cloud backup on sign-in.
- Local progress changes are backed up automatically with debounce.
- User can also press "Şimdi Yedekle" for manual backup.

## Free vs Guest

- Google/Apple signed-in users: free cloud backup and restore.
- Guest users: local-only SharedPreferences.
