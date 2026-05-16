# Premium Cloud Sync

## Scope

Premium users get cloud backup for:

- Dhikr count
- Qaza prayer counts
- Daily Quran page progress
- Daily streak

Free users stay local-only with `SharedPreferences`.

## Files

- `lib/core/services/cloud_sync_service.dart`
- `lib/core/services/gamification_service.dart`
- `lib/core/models/qaza_progress.dart`
- `lib/features/gamification/presentation/gamification_screen.dart`

## Firestore Path

```text
users/{uid}/premium_sync/ibadah_progress
```

## Sync Behavior

- Free users: local storage only.
- Premium users:
  - On Premium activation: restore cloud backup if cloud data is newer.
  - On local progress changes: backup is debounced in the background.
  - Manual backup: available from the gamification screen.
- Auth:
  - Uses existing FirebaseAuth user.
  - Falls back to anonymous Firebase Auth when needed.

## Data Shape

```json
{
  "qazaCounts": {},
  "quranPagesToday": 0,
  "dhikrToday": 0,
  "dailyQuranPageTarget": 5,
  "dailyDhikrTarget": 100,
  "streakDays": 0,
  "lastActivityDate": "ISO-8601",
  "updatedAt": "ISO-8601",
  "cloudUpdatedAt": "serverTimestamp",
  "schemaVersion": 1
}
```
