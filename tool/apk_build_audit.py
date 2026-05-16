#!/usr/bin/env python3
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / 'mobile_app'

def fail(m):
    print('❌ '+m); sys.exit(1)
files=[MOBILE/'android/app/build.gradle',MOBILE/'android/app/proguard-rules.pro',MOBILE/'android/app/src/main/AndroidManifest.xml',ROOT/'.github/workflows/build_apk.yml']
for f in files:
    if not f.exists(): fail(f'Missing {f.relative_to(ROOT)}')
bg=(MOBILE/'android/app/build.gradle').read_text()
for t in ['compileSdkVersion 34','targetSdkVersion 34','minSdkVersion 21','minifyEnabled true','shrinkResources true','proguard-rules.pro','coreLibraryDesugaring','signingConfig keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug']:
    if t not in bg: fail('build.gradle missing '+t)
manifest=(MOBILE/'android/app/src/main/AndroidManifest.xml').read_text()
for t in ['android.permission.INTERNET','com.android.vending.BILLING','android.permission.SCHEDULE_EXACT_ALARM','android.permission.RECEIVE_BOOT_COMPLETED','android.permission.ACCESS_FINE_LOCATION','android.permission.POST_NOTIFICATIONS']:
    if t not in manifest: fail('manifest missing '+t)
pro=(MOBILE/'android/app/proguard-rules.pro').read_text()
for t in ['com.google.android.gms.ads','com.revenuecat.purchases','com.android.billingclient','com.google.firebase','dev.fluttercommunity.plus.androidalarmmanager']:
    if t not in pro: fail('proguard missing '+t)
wf=(ROOT/'.github/workflows/build_apk.yml').read_text()
for t in ['subosito/flutter-action@v2','actions/setup-java@v4','flutter pub get','flutter build apk --release','actions/upload-artifact@v4','app-release.apk']:
    if t not in wf: fail('workflow missing '+t)
print('✅ APK build pipeline audit passed.')
