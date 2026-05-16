#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "mobile_app"

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    MOBILE / "lib/features/onboarding/presentation/language_country_setup_screen.dart",
    MOBILE / "lib/core/models/country_profile.dart",
    MOBILE / "lib/core/services/global_settings_service.dart",
    MOBILE / "lib/core/routing/app_router.dart",
    MOBILE / "lib/features/settings/presentation/settings_screen.dart",
    ROOT / "docs/LANGUAGE_COUNTRY_SETUP.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

screen = (MOBILE / "lib/features/onboarding/presentation/language_country_setup_screen.dart").read_text(encoding="utf-8")
for token in [
    "context.setLocale",
    "Locale('tr')",
    "Locale('en')",
    "Locale('ar')",
    "Locale('fr')",
    "Locale('ur')",
    "Locale('id')",
    "TextField",
    "CountryProfile.all",
    "currentPosition",
    "autoSelectCountry",
    "completeLanguageCountrySetup",
    "context.go(signedIn ? '/' : '/auth')",
    "🇹🇷",
    "🇸🇦",
    "🇵🇰",
    "🇮🇩",
]:
    if token not in screen:
        fail(f"Language setup screen token missing: {token}")

country = (MOBILE / "lib/core/models/country_profile.dart").read_text(encoding="utf-8")
for token in [
    "CalculationMethod.diyanet",
    "CalculationMethod.ummAlQura",
    "CalculationMethod.isna",
    "CalculationMethod.mwl",
    "byCoordinates",
    "contains",
    "TR",
    "SA",
    "US",
    "ID",
    "PK",
]:
    if token not in country:
        fail(f"CountryProfile token missing: {token}")

settings_service = (MOBILE / "lib/core/services/global_settings_service.dart").read_text(encoding="utf-8")
for token in [
    "languageCountrySetupCompleted",
    "completeLanguageCountrySetup",
    "resetLanguageCountrySetup",
    "setCountry",
    "autoSelectCountry",
    "_countryCode",
    "_languageCountrySetupCompleted",
]:
    if token not in settings_service:
        fail(f"GlobalSettings setup token missing: {token}")

router = (MOBILE / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
for token in [
    "initialLocation: '/language-country-setup'",
    "LanguageCountrySetupScreen",
    "editingLanguageSetup",
    "languageCountrySetupCompleted",
    "GoRoute(path: '/language-country-setup'",
]:
    if token not in router:
        fail(f"Router setup token missing: {token}")

settings = (MOBILE / "lib/features/settings/presentation/settings_screen.dart").read_text(encoding="utf-8")
for token in [
    "openLanguageCountrySetup",
    "/language-country-setup?edit=1",
    "globalSettings.country.flag",
    "globalSettings.country.label",
]:
    if token not in settings:
        fail(f"Settings setup button token missing: {token}")

main = (MOBILE / "lib/main.dart").read_text(encoding="utf-8")
for token in ["Locale('ur')", "Locale('id')", "GlobalSettingsService"]:
    if token not in main:
        fail(f"Main locale/service token missing: {token}")

for code in ["tr", "en", "ar", "fr", "ur", "id"]:
    path = MOBILE / "assets" / "translations" / f"{code}.json"
    if not path.exists():
        fail(f"Missing translation: {path.relative_to(ROOT)}")

quran = (MOBILE / "lib/core/services/quran_api_service.dart").read_text(encoding="utf-8")
for token in ["ur.jalandhry", "id.indonesian", "translationEditionForLocale"]:
    if token not in quran:
        fail(f"Quran locale token missing: {token}")

broken = []
for base in [MOBILE / "lib", ROOT / "admin_panel" / "lib"]:
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

print("✅ Language & Country Setup audit passed.")
