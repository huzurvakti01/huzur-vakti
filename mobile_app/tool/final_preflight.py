#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(msg):
    print(f"❌ {msg}")
    sys.exit(1)

def ok(msg):
    print(f"✅ {msg}")

required = [
    "pubspec.yaml",
    "lib/main.dart",
    "lib/core/routing/app_router.dart",
    "lib/core/services/ads/ad_service.dart",
    "lib/core/services/qibla_service.dart",
    "lib/core/services/finance_rate_service.dart",
    "assets/audio/fallback.mp3",
    "android/app/src/main/AndroidManifest.xml",
    "android/app/build.gradle",
    "android/key.properties.template",
    "ios/Runner/Info.plist",
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json",
    "tool/bootstrap_store_ready.sh",
    "docs/STORE_RELEASE_CHECKLIST.md",
]

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Eksik dosya: {rel}")
ok("Zorunlu dosyalar mevcut")

broken = []
for p in (ROOT / "lib").rglob("*.dart"):
    txt = p.read_text(encoding="utf-8", errors="ignore")
    for m in re.finditer(r"import\s+'([^']+)';", txt):
        imp = m.group(1)
        if imp.startswith(("package:", "dart:")):
            continue
        target = (p.parent / imp).resolve()
        if not target.exists():
            broken.append(f"{p.relative_to(ROOT)} -> {imp}")
if broken:
    fail("Bozuk importlar:\n" + "\n".join(broken))
ok("Dart relative importlar sağlam")

for p in ROOT.rglob("*"):
    if not p.is_file():
        continue
    if p.suffix.lower() not in {".dart", ".kt", ".swift", ".xml", ".yaml", ".gradle", ".plist", ".md"}:
        continue
    txt = p.read_text(encoding="utf-8", errors="ignore")
    if "TO" + "DO" in txt:
        fail(f"Yapılacak işaretçisi bulundu: {p.relative_to(ROOT)}")
ok("Yapılacak işaretçisi yok")

manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
for token in [
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "HuzurPrayerWidget",
    "AlarmBroadcastReceiver",
]:
    if token not in manifest:
        fail(f"Android manifest eksik: {token}")
ok("Android manifest kritik izinler/alıcılar mevcut")

plist = (ROOT / "ios/Runner/Info.plist").read_text(encoding="utf-8")
for token in ["NSSupportsLiveActivities", "UIBackgroundModes", "NSLocationWhenInUseUsageDescription"]:
    if token not in plist:
        fail(f"Info.plist eksik: {token}")
ok("iOS Info.plist kritik anahtarlar mevcut")

print("🎯 Final preflight passed.")
