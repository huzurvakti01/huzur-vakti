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
    MOBILE / "pubspec.yaml",
    MOBILE / "assets/translations/tr.json",
    MOBILE / "assets/translations/en.json",
    MOBILE / "assets/translations/ar.json",
    MOBILE / "assets/translations/fr.json",
    MOBILE / "lib/main.dart",
    MOBILE / "lib/core/models/calculation_method.dart",
    MOBILE / "lib/core/services/global_settings_service.dart",
    MOBILE / "lib/core/services/consent_service.dart",
    MOBILE / "lib/core/services/prayer_api_service.dart",
    MOBILE / "lib/core/services/quran_api_service.dart",
    MOBILE / "lib/core/state/prayer_controller.dart",
    MOBILE / "lib/features/settings/presentation/settings_screen.dart",
    ROOT / "docs/GLOBAL_EXPANSION_LOCALIZATION.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing file: {path.relative_to(ROOT)}")

pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
for token in ["easy_localization:", "flutter_localizations:", "assets/translations/"]:
    if token not in pubspec:
        fail(f"pubspec localization token missing: {token}")

main = (MOBILE / "lib/main.dart").read_text(encoding="utf-8")
for token in [
    "EasyLocalization.ensureInitialized",
    "EasyLocalization(",
    "supportedLocales: const [Locale('tr'), Locale('en'), Locale('ar'), Locale('fr')]",
    "context.locale",
    "context.supportedLocales",
    "context.localizationDelegates",
    "GlobalSettingsService",
    "ConsentService().requestConsent",
]:
    if token not in main:
        fail(f"main.dart token missing: {token}")

calc = (MOBILE / "lib/core/models/calculation_method.dart").read_text(encoding="utf-8")
for token in ["id: 13", "id: 3", "id: 2", "id: 4", "Diyanet", "Umm Al-Qura", "ISNA", "MWL"]:
    if token not in calc:
        fail(f"Calculation method missing: {token}")

settings_service = (MOBILE / "lib/core/services/global_settings_service.dart").read_text(encoding="utf-8")
for token in ["autoSelectCalculationMethod", "setHijriOffset", "setCalculationMethod", "clamp(-2, 2)"]:
    if token not in settings_service:
        fail(f"GlobalSettingsService token missing: {token}")

prayer = (MOBILE / "lib/core/services/prayer_api_service.dart").read_text(encoding="utf-8")
for token in ["calculationMethod", "hijriOffset", "'method':", "'adjustment':"]:
    if token not in prayer:
        fail(f"Prayer API global token missing: {token}")

controller = (MOBILE / "lib/core/state/prayer_controller.dart").read_text(encoding="utf-8")
for token in ["GlobalSettingsService", "calculationMethod: globalSettings.method.id", "hijriOffset: globalSettings.hijriOffset"]:
    if token not in controller:
        fail(f"PrayerController token missing: {token}")

quran = (MOBILE / "lib/core/services/quran_api_service.dart").read_text(encoding="utf-8")
for token in ["translationEditionForLocale", "tr.diyanet", "en.sahih", "fr.hamidullah", "ar.muyassar", "fetchSurahTranslationForLocale"]:
    if token not in quran:
        fail(f"Quran language token missing: {token}")

quran_screen = (MOBILE / "lib/features/quran/presentation/quran_screen.dart").read_text(encoding="utf-8")
for token in ["easy_localization", "context.locale.languageCode", "fetchSurahTranslationForLocale"]:
    if token not in quran_screen:
        fail(f"Quran screen locale token missing: {token}")

consent = (MOBILE / "lib/core/services/consent_service.dart").read_text(encoding="utf-8")
for token in ["ConsentInformation.instance.requestConsentInfoUpdate", "ConsentForm.loadAndShowConsentFormIfRequired", "ConsentForm.showPrivacyOptionsForm"]:
    if token not in consent:
        fail(f"UMP token missing: {token}")

settings = (MOBILE / "lib/features/settings/presentation/settings_screen.dart").read_text(encoding="utf-8")
for token in [
    "context.setLocale",
    "context.locale.languageCode",
    "CalculationMethod.all",
    "autoSelectCalculationMethod",
    "SegmentedButton<int>",
    "setHijriOffset",
    "showPrivacyOptions",
]:
    if token not in settings:
        fail(f"Settings global UI token missing: {token}")

broken = []
for path in (MOBILE / "lib").rglob("*.dart"):
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

print("✅ Global expansion localization audit passed.")
