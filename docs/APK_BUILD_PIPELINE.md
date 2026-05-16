# Android APK Build Pipeline

Configured files:

- `mobile_app/android/app/build.gradle`
- `mobile_app/android/app/proguard-rules.pro`
- `mobile_app/android/app/src/main/AndroidManifest.xml`
- `.github/workflows/build_apk.yml`

Release build target:

```bash
cd mobile_app
flutter build apk --release --no-tree-shake-icons
```

SDK policy:

- compileSdkVersion: 34
- targetSdkVersion: 34
- minSdkVersion: 21

Release optimization:

- R8 / Proguard enabled
- Resource shrinking enabled
- Desugaring enabled

Signing:

- Uses `android/key.properties` when available.
- Falls back to debug signing in CI so a release APK artifact is still generated for test distribution.
- For Play Store upload, configure the keystore secrets in GitHub Actions.
