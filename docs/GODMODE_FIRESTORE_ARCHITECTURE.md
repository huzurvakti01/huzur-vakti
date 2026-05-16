# God Mode Firestore Architecture

## Collection

```text
app_settings
```

Documents:

```text
app_settings/theme
app_settings/features
app_settings/ads
```

## Real-time Listener Strategy

Mobile should listen only to these small singleton documents:

```text
FirebaseFirestore.instance.doc('app_settings/theme').snapshots()
FirebaseFirestore.instance.doc('app_settings/features').snapshots()
FirebaseFirestore.instance.doc('app_settings/ads').snapshots()
```

These documents are intentionally tiny and singleton-based. Do not stream large collections for runtime configuration.

For lower quota pressure:

- Keep settings in 3 singleton documents.
- Use `revision` integers for cheap client-side diff decisions.
- Use Remote Config for feature flags and ad IDs where instant stream is not required.
- Use Firestore stream only for brand/theme/localization values that must visibly update in seconds.
- Avoid querying `app_settings` as a collection with filters; directly read known doc IDs.

## Security

Rules file:

```text
firestore_godmode.rules
```

Policy:

- Public read for `app_settings/*`
- Admin-only write through `request.auth.token.isAdmin == true`
- Schema validation for `theme`, `features`, `ads`
- Deny-all fallback

## Cloud Functions Autopilot Sync

Functions file:

```text
admin_panel/functions/index.js
```

Functions:

```text
syncGodModeThemeToRemoteConfig
syncGodModeFeaturesToRemoteConfig
syncGodModeAdsToRemoteConfig
seedGodModeAppSettings
```

Each Firestore document update publishes equivalent values to Firebase Remote Config and writes sync status into:

```text
app_settings_meta/sync_theme
app_settings_meta/sync_features
app_settings_meta/sync_ads
```
