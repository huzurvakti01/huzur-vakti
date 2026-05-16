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
    MOBILE / "lib/features/onboarding/presentation/smart_setup_screen.dart",
    MOBILE / "lib/core/routing/app_router.dart",
    MOBILE / "lib/core/services/global_settings_service.dart",
    MOBILE / "lib/core/models/country_profile.dart",
    MOBILE / "lib/core/services/location_service.dart",
    MOBILE / "lib/features/home/presentation/home_screen.dart",
    MOBILE / "lib/widgets/dashboard_native_ad.dart",
    MOBILE / "lib/core/services/consent_service.dart",
    MOBILE / "lib/core/services/revenuecat_service.dart",
    MOBILE / "lib/core/services/ai_chat_service.dart",
    MOBILE / "lib/features/support/presentation/helpdesk_screen.dart",
    ADMIN / "functions/index.js",
    ADMIN / "lib/screens/app_shell.dart",
    ROOT / "docs/AUTO_DETECT_SMART_ONBOARDING.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

screen = (MOBILE / "lib/features/onboarding/presentation/smart_setup_screen.dart").read_text(encoding="utf-8")
for token in [
    "dart:ui",
    "PlatformDispatcher.instance.locale",
    "LocationService",
    "currentPosition",
    "CountryProfile.byCoordinates",
    "context.setLocale",
    "TextDirection.rtl",
    "confirmAndContinue",
    "changeRegionLanguage",
    "smartSetupManualSelection",
    "Locale('tr')",
    "Locale('en')",
    "Locale('ar')",
    "Locale('fr')",
    "Locale('ur')",
    "Locale('id')",
    "completeLanguageCountrySetup",
    "setCountry",
]:
    if token not in screen:
        fail(f"Smart setup token missing: {token}")

router = (MOBILE / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
for token in [
    "initialLocation: '/smart-setup'",
    "SmartSetupScreen",
    "GoRoute(path: '/smart-setup'",
    "onSmartSetup",
    "languageCountrySetupCompleted",
]:
    if token not in router:
        fail(f"Router smart setup token missing: {token}")

settings = (MOBILE / "lib/features/settings/presentation/settings_screen.dart").read_text(encoding="utf-8")
if "/smart-setup?edit=1" not in settings:
    fail("Settings must reopen smart setup in edit mode")

country = (MOBILE / "lib/core/models/country_profile.dart").read_text(encoding="utf-8")
for token in ["TR", "SA", "US", "PK", "ID", "byCoordinates", "CalculationMethod.diyanet", "CalculationMethod.ummAlQura", "CalculationMethod.isna", "CalculationMethod.mwl"]:
    if token not in country:
        fail(f"Country profile token missing: {token}")

global_settings = (MOBILE / "lib/core/services/global_settings_service.dart").read_text(encoding="utf-8")
for token in ["completeLanguageCountrySetup", "languageCountrySetupCompleted", "setCountry", "autoSelectCountry", "_countryCode"]:
    if token not in global_settings:
        fail(f"Global settings token missing: {token}")

for code in ["tr", "en", "ar", "fr", "ur", "id"]:
    if not (MOBILE / "assets" / "translations" / f"{code}.json").exists():
        fail(f"Missing translation: {code}.json")

shell = (MOBILE / "lib/features/shell/presentation/main_shell.dart").read_text(encoding="utf-8")
for token in ["navHome", "navQuranHub", "navToolsCompass", "navAssistantSupport"]:
    if token not in shell:
        fail(f"Bottom nav token missing: {token}")
if shell.count("NavigationDestination") != 4:
    fail("Bottom navigation must have exactly 4 tabs")

home = (MOBILE / "lib/features/home/presentation/home_screen.dart").read_text(encoding="utf-8")
for token in ["_PrayerRingPainter", "wavePath", "DashboardNativeAd", "ReligiousContentService", "_InspirationStories"]:
    if token not in home:
        fail(f"Home dashboard token missing: {token}")

quran = (MOBILE / "lib/core/services/quran_api_service.dart").read_text(encoding="utf-8")
for token in ["api.alquran.cloud", "ar.alafasy", "translationEditionForLocale", "ur.jalandhry", "id.indonesian"]:
    if token not in quran:
        fail(f"Quran global token missing: {token}")

media = (MOBILE / "lib/core/services/media_center_service.dart").read_text(encoding="utf-8")
for token in ["makkah_live", "madinah_live", "quran_radio", "playRadio"]:
    if token not in media:
        fail(f"Media token missing: {token}")

ads = (MOBILE / "lib/core/services/ads/ad_service.dart").read_text(encoding="utf-8")
for token in ["nativeUnitId", "showInterstitialIfReady", "isPremium", "globallyDisabled"]:
    if token not in ads:
        fail(f"Ad service token missing: {token}")

consent = (MOBILE / "lib/core/services/consent_service.dart").read_text(encoding="utf-8")
for token in ["ConsentInformation.instance.requestConsentInfoUpdate", "ConsentForm.loadAndShowConsentFormIfRequired"]:
    if token not in consent:
        fail(f"UMP token missing: {token}")

revenue = (MOBILE / "lib/core/services/revenuecat_service.dart").read_text(encoding="utf-8")
for token in ["Purchases.configure", "purchasePackage", "entitlements.active"]:
    if token not in revenue:
        fail(f"RevenueCat token missing: {token}")

ai = (MOBILE / "lib/core/services/ai_chat_service.dart").read_text(encoding="utf-8")
for token in ["'model': 'gpt-4o'", "languageCode", "isPremium", "freeDailyLimit"]:
    if token not in ai:
        fail(f"AI token missing: {token}")

helpdesk = (MOBILE / "lib/core/services/helpdesk_service.dart").read_text(encoding="utf-8")
if "support_tickets" not in helpdesk:
    fail("Helpdesk service must write support_tickets")

functions = (ADMIN / "functions/index.js").read_text(encoding="utf-8")
for token in ["OPENAI_API_KEY", "aiModerateDuaOnCreate", "generateDailyIslamicContent", "publishKillSwitchConfig", "banUserDevice"]:
    if token not in functions:
        fail(f"Admin God Mode token missing: {token}")

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

print("✅ AutoDetect Final audit passed.")
