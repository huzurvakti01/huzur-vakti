#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ADMIN = ROOT / "admin_panel"

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    ADMIN / "lib/screens/god_mode_studio.dart",
    ADMIN / "lib/screens/app_shell.dart",
    ADMIN / "lib/services/functions_service.dart",
    ADMIN / "functions/index.js",
    ADMIN / "pubspec.yaml",
    ROOT / "docs/ADMIN_APP_ENGINE_BRAND_CONTROLLER.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

pubspec = (ADMIN / "pubspec.yaml").read_text(encoding="utf-8")
for token in ["firebase_storage:", "file_picker:", "cloud_firestore:", "cloud_functions:"]:
    if token not in pubspec:
        fail(f"Admin pubspec dependency missing: {token}")

studio = (ADMIN / "lib/screens/god_mode_studio.dart").read_text(encoding="utf-8")
for token in [
    "class GodModeStudioScreen",
    "FirebaseStorage.instance",
    "FilePicker.platform.pickFiles",
    "allowedExtensions: ['png']",
    "brand_assets/logo_main_",
    "putData",
    "getDownloadURL",
    "app_settings",
    "themeRef",
    "logoUrl",
    "splashImageUrl",
    "primaryColor",
    "publishRemoteConfigValues",
    "isAiEnabled",
    "isWomenCalendarVisible",
    "isSeferiModeActive",
    "isMediaCenterActive",
    "admobNativeAndroidId",
    "admobInterstitialAndroidId",
    "premiumMonthlyLabel",
    "translationOverrideRef",
    "localization_override",
    "tr",
    "en",
    "ar",
    "fr",
    "ur",
    "id",
    "DataTable",
]:
    if token not in studio:
        fail(f"GodModeStudio token missing: {token}")

shell = (ADMIN / "lib/screens/app_shell.dart").read_text(encoding="utf-8")
for token in [
    "god_mode_studio.dart",
    "GodModeStudioScreen()",
    "App Engine",
    "Icons.app_settings_alt_rounded",
]:
    if token not in shell:
        fail(f"AppShell integration token missing: {token}")

functions_service = (ADMIN / "lib/services/functions_service.dart").read_text(encoding="utf-8")
for token in [
    "publishRemoteConfigValues",
    "httpsCallable('publishRemoteConfigValues')",
]:
    if token not in functions_service:
        fail(f"FunctionsService token missing: {token}")

functions = (ADMIN / "functions/index.js").read_text(encoding="utf-8")
for token in [
    "export const publishRemoteConfigValues",
    "assertAdmin(request)",
    "remoteConfig.getTemplate",
    "remoteConfig.publishTemplate",
    "isAiEnabled",
    "isWomenCalendarVisible",
    "admobNativeAndroidId",
    "premiumDiscountLabel",
    "app_engine_remote_config_published",
]:
    if token not in functions:
        fail(f"Cloud Function Remote Config token missing: {token}")

broken = []
for path in (ADMIN / "lib").rglob("*.dart"):
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

print("✅ Admin App Engine & Brand Controller audit passed.")
