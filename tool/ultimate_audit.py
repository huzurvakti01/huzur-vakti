#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "mobile_app"
ADMIN = ROOT / "admin_panel"

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    MOBILE / "lib/main.dart",
    MOBILE / "lib/core/routing/app_router.dart",
    MOBILE / "lib/features/shell/presentation/main_shell.dart",
    MOBILE / "lib/features/home/presentation/home_screen.dart",
    MOBILE / "lib/widgets/dashboard_native_ad.dart",
    MOBILE / "lib/features/quran/presentation/quran_screen.dart",
    MOBILE / "lib/core/services/quran_api_service.dart",
    MOBILE / "lib/core/services/gallery_service.dart",
    MOBILE / "lib/core/services/revenuecat_service.dart",
    MOBILE / "lib/core/services/helpdesk_service.dart",
    MOBILE / "lib/features/support/presentation/helpdesk_screen.dart",
    MOBILE / "lib/features/support/presentation/assistant_support_hub_screen.dart",
    MOBILE / "lib/features/onboarding/presentation/onboarding_screen.dart",
    ADMIN / "lib/main.dart",
    ADMIN / "lib/screens/app_shell.dart",
    ADMIN / "lib/screens/support_tickets_screen.dart",
    ADMIN / "lib/services/support_ticket_service.dart",
    ADMIN / "functions/index.js",
    ROOT / "README.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
for dep in [
    "provider:",
    "go_router:",
    "http:",
    "google_mobile_ads:",
    "purchases_flutter:",
    "firebase_auth:",
    "cloud_firestore:",
    "just_audio:",
    "youtube_player_flutter:",
    "share_plus:",
    "permission_handler:",
    "hive_flutter:",
]:
    if dep not in pubspec:
        fail(f"Missing mobile dependency: {dep}")

router = (MOBILE / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
for route in [
    "/onboarding",
    "/",
    "/quran",
    "/tools",
    "/assistant-support",
    "/helpdesk",
    "/wallpapers",
    "/media-center",
    "/women-calendar",
    "/prayer-dnd",
]:
    if route not in router:
        fail(f"Missing route: {route}")

shell = (MOBILE / "lib/features/shell/presentation/main_shell.dart").read_text(encoding="utf-8")
for label in ["navHome", "navQuranHub", "navToolsCompass", "navAssistantSupport"]:
    if label not in shell:
        fail(f"Bottom navigation label missing: {label}")
if shell.count("NavigationDestination") != 4:
    fail("Mobile bottom navigation must have exactly 4 destinations")

home = (MOBILE / "lib/features/home/presentation/home_screen.dart").read_text(encoding="utf-8")
for token in ["DashboardNativeAd", "_HeroPrayerCard", "_QuickActions"]:
    if token not in home:
        fail(f"Dashboard token missing: {token}")

quran = (MOBILE / "lib/core/services/quran_api_service.dart").read_text(encoding="utf-8")
for token in ["api.alquran.cloud", "tr.diyanet", "ar.alafasy", "fetchSurahTranslationTr", "fetchSurahAudioAlafasy"]:
    if token not in quran:
        fail(f"Quran real-data token missing: {token}")

prayer = (MOBILE / "lib/core/services/prayer_api_service.dart").read_text(encoding="utf-8")
for token in ["api.aladhan.com", "AppConstants.aladhanMethod"]:
    if token not in prayer:
        fail(f"Prayer API token missing: {token}")

gallery = (MOBILE / "lib/core/services/gallery_service.dart").read_text(encoding="utf-8")
for token in ["api.unsplash.com", "images.unsplash.com", "fetchIslamicWallpapers"]:
    if token not in gallery:
        fail(f"Gallery token missing: {token}")

helpdesk = (MOBILE / "lib/core/services/helpdesk_service.dart").read_text(encoding="utf-8")
for token in ["support_tickets", "FirebaseFirestore", "createTicket"]:
    if token not in helpdesk:
        fail(f"Helpdesk token missing: {token}")

revenue = (MOBILE / "lib/core/services/revenuecat_service.dart").read_text(encoding="utf-8")
for token in ["Purchases.configure", "purchasePackage", "entitlements.active"]:
    if token not in revenue:
        fail(f"RevenueCat token missing: {token}")

onboarding = (MOBILE / "lib/features/onboarding/presentation/onboarding_screen.dart").read_text(encoding="utf-8")
for token in ["Permission.locationWhenInUse", "Permission.locationAlways", "Permission.notification"]:
    if token not in onboarding:
        fail(f"Onboarding permission token missing: {token}")

manifest = (MOBILE / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
for token in [
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_BACKGROUND_LOCATION",
    "android.permission.RECORD_AUDIO",
    "android.permission.POST_NOTIFICATIONS",
]:
    if token not in manifest:
        fail(f"Android permission missing: {token}")

plist = (MOBILE / "ios/Runner/Info.plist").read_text(encoding="utf-8")
for token in [
    "NSLocationWhenInUseUsageDescription",
    "NSLocationAlwaysAndWhenInUseUsageDescription",
    "NSMicrophoneUsageDescription",
    "NSUserTrackingUsageDescription",
]:
    if token not in plist:
        fail(f"iOS permission text missing: {token}")

admin_shell = (ADMIN / "lib/screens/app_shell.dart").read_text(encoding="utf-8")
if "SupportTicketsScreen" not in admin_shell:
    fail("Admin support tickets screen not connected")
if admin_shell.count("NavigationRailDestination") != 7:
    fail("Admin NavigationRail should have 7 destinations")

admin_main = (ADMIN / "lib/main.dart").read_text(encoding="utf-8")
if "SupportTicketService" not in admin_main:
    fail("Admin SupportTicketService provider missing")

admin_support = (ADMIN / "lib/screens/support_tickets_screen.dart").read_text(encoding="utf-8")
admin_support_service = (ADMIN / "lib/services/support_ticket_service.dart").read_text(encoding="utf-8")
for token in ["reply", "close", "Destek Talepleri"]:
    if token not in admin_support:
        fail(f"Admin support token missing: {token}")
if "support_tickets" not in admin_support_service:
    fail("Admin support service Firestore collection missing: support_tickets")

functions = (ADMIN / "functions/index.js").read_text(encoding="utf-8")
for token in ["OPENAI_API_KEY", "aiModerateDuaOnCreate", "generateDailyIslamicContent", "banUserDevice", "publishKillSwitchConfig"]:
    if token not in functions:
        fail(f"God Mode function token missing: {token}")

for blocked in ["TODO", "Demo", "dummy", "mock"]:
    hits = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".dart", ".js", ".yaml", ".yml", ".json", ".xml", ".plist", ".md", ".rules", ".kt", ".swift"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if re.search(rf"\b{re.escape(blocked)}\b", text, re.IGNORECASE):
            hits.append(str(path.relative_to(ROOT)))
    if hits:
        fail(f"Blocked placeholder term found: {blocked}\n" + "\n".join(hits))

broken = []
for base in [MOBILE / "lib", ADMIN / "lib"]:
    for path in base.rglob("*.dart"):
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

print("✅ Ultimate source audit passed.")
