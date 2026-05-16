#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
INFO = ROOT / "ios/Runner/Info.plist"
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"

required_ios = [
    "NSUserTrackingUsageDescription",
    "NSLocationWhenInUseUsageDescription",
    "NSLocationAlwaysAndWhenInUseUsageDescription",
    "NSLocationAlwaysUsageDescription",
    "NSUserNotificationUsageDescription",
    "NSMotionUsageDescription",
    "NSSupportsLiveActivities",
    "UIBackgroundModes",
    "GADApplicationIdentifier",
    "LSApplicationQueriesSchemes",
]

required_android = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_BACKGROUND_LOCATION",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.USE_EXACT_ALARM",
    "android.permission.USE_FULL_SCREEN_INTENT",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
    "android.permission.FOREGROUND_SERVICE_LOCATION",
    "android.permission.FOREGROUND_SERVICE_DATA_SYNC",
    "com.google.android.gms.ads.APPLICATION_ID",
    "com.google.android.geo.API_KEY",
    "HuzurPrayerWidget",
    "AlarmBroadcastReceiver",
    "RebootBroadcastReceiver",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

if not INFO.exists():
    fail("iOS Info.plist missing")
if not MANIFEST.exists():
    fail("AndroidManifest.xml missing")

info_text = INFO.read_text(encoding="utf-8")
manifest_text = MANIFEST.read_text(encoding="utf-8")

missing_ios = [key for key in required_ios if key not in info_text]
missing_android = [key for key in required_android if key not in manifest_text]

if missing_ios:
    fail("Missing iOS permission keys: " + ", ".join(missing_ios))
if missing_android:
    fail("Missing Android permissions/meta-data: " + ", ".join(missing_android))

print("✅ Permissions audit passed.")
