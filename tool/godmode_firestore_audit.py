#!/usr/bin/env python3
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ADMIN = ROOT / "admin_panel"

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    ROOT / "firestore_godmode.rules",
    ROOT / "docs/GODMODE_FIRESTORE_SCHEMA.json",
    ROOT / "docs/GODMODE_FIRESTORE_ARCHITECTURE.md",
    ADMIN / "functions/index.js",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

rules = (ROOT / "firestore_godmode.rules").read_text(encoding="utf-8")
for token in [
    "rules_version = '2'",
    "function isAdmin()",
    "request.auth.token.isAdmin == true",
    "match /app_settings/{docId}",
    "allow read: if true",
    "allow create, update: if isAdmin()",
    "docId == 'theme'",
    "docId == 'features'",
    "docId == 'ads'",
    "validTheme()",
    "validFeatures()",
    "validAds()",
    "logoUrl",
    "splashImageUrl",
    "colors.primary",
    "fontStyle.family",
    "ai_active",
    "widgets_active",
    "banner_id_android",
    "interstitial_id_ios",
    "frequency >= 1",
    "allow read, write: if false",
]:
    if token not in rules:
        fail(f"firestore_godmode.rules token missing: {token}")

for forbidden in [
    "allow write: if true",
    "allow create, update: if true",
    "allow read, write: if true",
]:
    if forbidden in rules:
        fail(f"Insecure rule found: {forbidden}")

schema = json.loads((ROOT / "docs/GODMODE_FIRESTORE_SCHEMA.json").read_text(encoding="utf-8"))
for doc in ["app_settings/theme", "app_settings/features", "app_settings/ads"]:
    if doc not in schema:
        fail(f"Schema missing {doc}")

for key in ["logoUrl", "colors", "fontStyle", "primaryColor"]:
    if key not in schema["app_settings/theme"]:
        fail(f"theme schema missing {key}")

for key in ["ai_active", "widgets_active", "women_calendar_active", "seferi_mode_active", "media_center_active"]:
    if key not in schema["app_settings/features"]:
        fail(f"features schema missing {key}")

for key in ["banner_id_android", "interstitial_id", "frequency"]:
    raw = json.dumps(schema["app_settings/ads"], ensure_ascii=False)
    if key not in raw:
        fail(f"ads schema missing {key}")

functions = (ADMIN / "functions/index.js").read_text(encoding="utf-8")
for token in [
    "onDocumentWritten",
    "syncGodModeThemeToRemoteConfig",
    "syncGodModeFeaturesToRemoteConfig",
    "syncGodModeAdsToRemoteConfig",
    "seedGodModeAppSettings",
    "publishGodModeRemoteConfig",
    "themeToRemoteConfig",
    "featuresToRemoteConfig",
    "adsToRemoteConfig",
    "writeGodModeSyncMeta",
    "app_settings/theme",
    "app_settings/features",
    "app_settings/ads",
    "app_settings_meta",
    "godmode_logo_url",
    "isAiEnabled",
    "isWomenCalendarVisible",
    "isSeferiModeActive",
    "isMediaCenterActive",
    "admobNativeAndroidId",
    "interstitialFrequency",
    "remoteConfig().getTemplate",
    "remoteConfig().publishTemplate",
    "assertAdmin(request)",
]:
    if token not in functions:
        fail(f"Cloud Functions God Mode sync token missing: {token}")

if "require(" in functions:
    fail("Cloud Functions must stay ESM-only; CommonJS require found")

print("✅ God Mode Firestore rules and autopilot sync audit passed.")
