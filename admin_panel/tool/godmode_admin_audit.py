#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "pubspec.yaml",
    "lib/main.dart",
    "lib/firebase_options.dart",
    "lib/screens/app_shell.dart",
    "lib/screens/login_screen.dart",
    "lib/screens/dashboard_screen.dart",
    "lib/screens/user_matrix_screen.dart",
    "lib/screens/absolute_moderation_screen.dart",
    "lib/screens/kill_switch_screen.dart",
    "lib/screens/cms_studio_screen.dart",
    "lib/services/auth_service.dart",
    "lib/services/functions_service.dart",
    "lib/services/user_matrix_service.dart",
    "lib/services/moderation_service.dart",
    "lib/services/kill_switch_service.dart",
    "lib/services/cms_service.dart",
    "lib/models/admin_user_matrix.dart",
    "lib/models/dua_admin_record.dart",
    "lib/models/kill_switch_config.dart",
    "lib/models/cms_content.dart",
    "functions/index.js",
    "functions/package.json",
    "firestore.rules",
    "docs/GODMODE_ADMIN_ARCHITECTURE.md",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in ["firebase_core:", "firebase_auth:", "cloud_firestore:", "cloud_functions:", "provider:", "google_fonts:"]:
    if dep not in pubspec:
        fail(f"Missing dependency: {dep}")

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
for token in ["Firebase.initializeApp", "AuthService", "UserMatrixService", "ModerationService", "KillSwitchService", "CmsService"]:
    if token not in main:
        fail(f"main.dart integration missing: {token}")

shell = (ROOT / "lib/screens/app_shell.dart").read_text(encoding="utf-8")
for token in ["NavigationRail", "User Matrix", "Moderation", "Kill Switch", "CMS"]:
    if token not in shell:
        fail(f"Shell navigation missing: {token}")

user_matrix = (ROOT / "lib/screens/user_matrix_screen.dart").read_text(encoding="utf-8")
for token in ["Hard Delete", "Zikir Sayısı", "Premium", "VIP", "Kaza", "hardDelete"]:
    if token not in user_matrix:
        fail(f"User Matrix feature missing: {token}")

moderation = (ROOT / "lib/screens/absolute_moderation_screen.dart").read_text(encoding="utf-8")
for token in ["Author UID", "updateDua", "deleteDua", "Şikayet"]:
    if token not in moderation:
        fail(f"Absolute Moderation feature missing: {token}")

kill = (ROOT / "lib/screens/kill_switch_screen.dart").read_text(encoding="utf-8")
for token in ["Zorunlu Güncelleme", "Min. Versiyon Kodu", "AI Sohbet", "Zikirmatik", "Cloud Sync", "publish"]:
    if token not in kill:
        fail(f"Kill Switch feature missing: {token}")

cms = (ROOT / "lib/screens/cms_studio_screen.dart").read_text(encoding="utf-8")
for token in ["Günün Ayeti", "Günün Hadisi", "Hakkımızda", "upsertContent"]:
    if token not in cms:
        fail(f"CMS feature missing: {token}")

functions = (ROOT / "functions/index.js").read_text(encoding="utf-8")
for fn in ["assertGodModeAdmin", "listAuthUsers", "updateUserGodMode", "hardDeleteUser", "publishKillSwitchConfig"]:
    if fn not in functions:
        fail(f"Cloud Function missing: {fn}")

for blocked in ["TODO", "dummy", "mock"]:
    hits = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".dart", ".js", ".json", ".yaml", ".md", ".rules"}:
            continue
        if re.search(rf"\b{re.escape(blocked)}\b", path.read_text(encoding="utf-8", errors="ignore"), re.IGNORECASE):
            hits.append(str(path.relative_to(ROOT)))
    if hits:
        fail(f"Blocked placeholder term found: {blocked}\\n" + "\\n".join(hits))

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
    fail("Broken Dart imports found:\\n" + "\\n".join(broken))

print("✅ God Mode Admin audit passed.")
