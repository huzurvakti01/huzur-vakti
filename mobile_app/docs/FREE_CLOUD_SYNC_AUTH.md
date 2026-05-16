# Free Cloud Sync + Authentication

## Decision

Cloud Sync is no longer Premium-only. It is free for every signed-in user.

## Auth

Files:

- `lib/core/services/auth_service.dart`
- `lib/features/auth/presentation/auth_screen.dart`

Packages:

- `firebase_auth`
- `google_sign_in`
- `sign_in_with_apple`
- `crypto`

Supported sign-in methods:

- Google
- Apple
- Guest mode

Guest mode keeps data local. Google/Apple sign-in enables cloud restore after reinstall or new device login.

## Firestore Sync

Files:

- `lib/core/services/cloud_sync_service.dart`
- `lib/core/services/gamification_service.dart`

Path:

```text
users/{uid}/cloud_sync/ibadah_progress
```

Synced data:

- Dhikr count
- Qaza prayer counts
- Quran page progress
- Daily streak

## Behavior

- Signed-in users: free Firestore backup and restore.
- Guest users: local-only SharedPreferences.
- On sign-in: restores cloud data if cloud version is newer.
- On progress change: debounced cloud backup.
- Manual backup remains available from the gamification screen.
