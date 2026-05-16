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
    MOBILE / "pubspec.yaml",
    MOBILE / "lib/main.dart",
    MOBILE / "lib/core/routing/app_router.dart",
    MOBILE / "lib/features/shell/presentation/main_shell.dart",
    MOBILE / "lib/features/settings/presentation/settings_screen.dart",
    MOBILE / "lib/core/services/global_settings_service.dart",
    MOBILE / "lib/core/services/consent_service.dart",
    MOBILE / "lib/core/services/quran_api_service.dart",
    MOBILE / "lib/core/services/gallery_service.dart",
    MOBILE / "lib/widgets/dashboard_native_ad.dart",
    ADMIN / "lib/main.dart",
    ADMIN / "functions/index.js",
    ADMIN / "lib/screens/support_tickets_screen.dart",
    ROOT / "docs/GLOBAL_SUPERAPP_6_LANG_MANIFEST.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

for code in ["tr", "en", "ar", "fr", "ur", "id"]:
    path = MOBILE / "assets" / "translations" / f"{code}.json"
    if not path.exists():
        fail(f"Missing translation asset: {path.relative_to(ROOT)}")
    if path.stat().st_size < 30:
        fail(f"Translation asset too small: {path.relative_to(ROOT)}")

pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
for token in ["easy_localization:", "flutter_localizations:", "assets/translations/"]:
    if token not in pubspec:
        fail(f"Localization pubspec token missing: {token}")

main = (MOBILE / "lib/main.dart").read_text(encoding="utf-8")
for token in [
    "EasyLocalization.ensureInitialized",
    "EasyLocalization(",
    "Locale('tr')",
    "Locale('en')",
    "Locale('ar')",
    "Locale('fr')",
    "Locale('ur')",
    "Locale('id')",
    "context.locale",
    "context.supportedLocales",
    "context.localizationDelegates",
]:
    if token not in main:
        fail(f"main.dart locale token missing: {token}")

settings = (MOBILE / "lib/features/settings/presentation/settings_screen.dart").read_text(encoding="utf-8")
for token in [
    "Locale('tr')",
    "Locale('en')",
    "Locale('ar')",
    "Locale('fr')",
    "Locale('ur')",
    "Locale('id')",
    "context.setLocale",
    "CalculationMethod.all",
    "autoSelectCalculationMethod",
    "setHijriOffset",
    "showPrivacyOptions",
]:
    if token not in settings:
        fail(f"Settings token missing: {token}")

quran = (MOBILE / "lib/core/services/quran_api_service.dart").read_text(encoding="utf-8")
for token in [
    "translationEditionForLocale",
    "tr.diyanet",
    "en.sahih",
    "ar.muyassar",
    "fr.hamidullah",
    "ur.jalandhry",
    "id.indonesian",
    "fetchSurahTranslationForLocale",
]:
    if token not in quran:
        fail(f"Quran locale token missing: {token}")

global_settings = (MOBILE / "lib/core/services/global_settings_service.dart").read_text(encoding="utf-8")
for token in ["autoSelectCalculationMethod", "CalculationMethod.diyanet", "CalculationMethod.ummAlQura", "CalculationMethod.isna", "CalculationMethod.mwl", "clamp(-2, 2)"]:
    if token not in global_settings:
        fail(f"Global settings token missing: {token}")

consent = (MOBILE / "lib/core/services/consent_service.dart").read_text(encoding="utf-8")
for token in ["ConsentInformation.instance.requestConsentInfoUpdate", "ConsentForm.loadAndShowConsentFormIfRequired", "ConsentForm.showPrivacyOptionsForm"]:
    if token not in consent:
        fail(f"UMP consent token missing: {token}")

shell = (MOBILE / "lib/features/shell/presentation/main_shell.dart").read_text(encoding="utf-8")
for token in ["navHome", "navQuranHub", "navToolsCompass", "navAssistantSupport"]:
    if token not in shell:
        fail(f"BottomBar token missing: {token}")
if shell.count("NavigationDestination") != 4:
    fail("Mobile Bottom Navigation must have exactly 4 destinations")

gallery = (MOBILE / "lib/core/services/gallery_service.dart").read_text(encoding="utf-8")
for token in ["api.unsplash.com", "images.unsplash.com", "fetchIslamicWallpapers"]:
    if token not in gallery:
        fail(f"Gallery no-empty token missing: {token}")

admin_functions = (ADMIN / "functions/index.js").read_text(encoding="utf-8")
for token in ["OPENAI_API_KEY", "aiModerateDuaOnCreate", "generateDailyIslamicContent", "publishKillSwitchConfig", "banUserDevice"]:
    if token not in admin_functions:
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

print("✅ Global SuperApp 6-language audit passed.")
