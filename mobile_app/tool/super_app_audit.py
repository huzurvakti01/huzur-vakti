#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "lib/features/super_app/presentation/super_app_hub_screen.dart",
    "lib/features/media/presentation/media_center_screen.dart",
    "lib/features/women/presentation/women_calendar_screen.dart",
    "lib/features/tools/presentation/prayer_dnd_screen.dart",
    "lib/features/tools/presentation/greeting_card_screen.dart",
    "lib/features/quran_tools/presentation/khutbah_moon_screen.dart",
    "lib/features/quran_tools/presentation/ayah_finder_screen.dart",
    "lib/core/services/media_center_service.dart",
    "lib/core/services/women_calendar_service.dart",
    "lib/core/services/prayer_dnd_service.dart",
    "lib/core/services/greeting_card_service.dart",
    "lib/core/services/khutbah_service.dart",
    "lib/core/services/ayah_finder_service.dart",
    "docs/SUPER_APP_MODULES.md",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in [
    "youtube_player_flutter:",
    "just_audio:",
    "hive:",
    "hive_flutter:",
    "flutter_dnd:",
    "share_plus:",
    "permission_handler:",
    "record:",
    "image:",
]:
    if dep not in pubspec:
        fail(f"Missing dependency: {dep}")

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
for token in [
    "WomenCalendarService",
    "MediaCenterService",
    "PrayerDndService",
    "GreetingCardService",
    "AyahFinderService",
    "women_calendar_hive",
]:
    if token not in main:
        fail(f"main.dart integration missing: {token}")

router = (ROOT / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
for route in [
    "/super",
    "/media-center",
    "/women-calendar",
    "/prayer-dnd",
    "/greeting-card",
    "/khutbah",
    "/ayah-finder",
]:
    if route not in router:
        fail(f"Route missing: {route}")

shell = (ROOT / "lib/features/shell/presentation/main_shell.dart").read_text(encoding="utf-8")
for label in ["navPrayer", "appName", "navSocial", "navTools"]:
    if label not in shell:
        fail(f"Bottom navigation label missing: {label}")
if shell.count("NavigationDestination") != 4:
    fail("BottomNavigation must have exactly 4 top-level destinations")

hub = (ROOT / "lib/features/super_app/presentation/super_app_hub_screen.dart").read_text(encoding="utf-8")
for token in ["TabBar", "navIbadah", "media-center", "women-calendar", "ayah-finder", "SafeBannerAd", "trackNavigation"]:
    if token not in hub:
        fail(f"Super hub token missing: {token}")

media = (ROOT / "lib/features/media/presentation/media_center_screen.dart").read_text(encoding="utf-8")
for token in ["YoutubePlayer", "MediaCenterService", "PurchaseService", "mediaNoAds"]:
    if token not in media:
        fail(f"Media center token missing: {token}")
if "SafeBannerAd" in media:
    fail("Media center must not show banner ads during playback")

women = (ROOT / "lib/features/women/presentation/women_calendar_screen.dart").read_text(encoding="utf-8")
for token in ["WomenCalendarService", "SafeBannerAd", "trackButtonTap"]:
    if token not in women:
        fail(f"Women calendar token missing: {token}")

dnd = (ROOT / "lib/features/tools/presentation/prayer_dnd_screen.dart").read_text(encoding="utf-8")
for token in ["PrayerDndService", "SafeBannerAd", "trackButtonTap"]:
    if token not in dnd:
        fail(f"DND token missing: {token}")

card = (ROOT / "lib/features/tools/presentation/greeting_card_screen.dart").read_text(encoding="utf-8")
for token in ["GreetingCardService", "Share.shareXFiles", "SafeBannerAd", "trackButtonTap"]:
    if token not in card:
        fail(f"Greeting card token missing: {token}")

khutbah = (ROOT / "lib/features/quran_tools/presentation/khutbah_moon_screen.dart").read_text(encoding="utf-8")
for token in ["KhutbahService", "MoonPhaseService", "SafeBannerAd"]:
    if token not in khutbah:
        fail(f"Khutbah token missing: {token}")

ayah = (ROOT / "lib/features/quran_tools/presentation/ayah_finder_screen.dart").read_text(encoding="utf-8")
for token in ["AudioRecorder", "Permission.microphone", "AyahFinderService", "SafeBannerAd", "_RadarPainter"]:
    if token not in ayah:
        fail(f"Ayah finder token missing: {token}")

constants = (ROOT / "lib/core/config/app_constants.dart").read_text(encoding="utf-8")
for key in ["media_center", "quran_radio", "live_stream"]:
    if key not in constants:
        fail(f"Media no-ad screen key missing: {key}")

manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
for perm in ["android.permission.RECORD_AUDIO", "android.permission.ACCESS_NOTIFICATION_POLICY"]:
    if perm not in manifest:
        fail(f"Android permission missing: {perm}")

plist = (ROOT / "ios/Runner/Info.plist").read_text(encoding="utf-8")
if "NSMicrophoneUsageDescription" not in plist:
    fail("iOS microphone usage description missing")

broken = []
for path in (ROOT / "lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    rel = str(path.relative_to(ROOT))
    for match in re.finditer(r"import\s+'([^']+)';", text):
        imp = match.group(1)
        if imp.startswith(("package:", "dart:")):
            continue
        if not (path.parent / imp).resolve().exists():
            broken.append(f"{rel} -> {imp}")

if broken:
    fail("Broken Dart imports found:\n" + "\n".join(broken))

print("✅ Super App modules audit passed.")
