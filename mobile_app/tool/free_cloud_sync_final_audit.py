#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "lib/core/services/cloud_sync_service.dart",
    "lib/core/services/auth_service.dart",
    "lib/core/services/gamification_service.dart",
    "lib/features/auth/presentation/auth_screen.dart",
    "lib/features/gamification/presentation/gamification_screen.dart",
    "docs/FREE_CLOUD_SYNC_FINAL.md",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in ["firebase_auth:", "cloud_firestore:", "google_sign_in:", "sign_in_with_apple:", "shared_preferences:"]:
    if dep not in pubspec:
        fail(f"Missing dependency: {dep}")

cloud = (ROOT / "lib/core/services/cloud_sync_service.dart").read_text(encoding="utf-8")
for token in ["backupProgress", "restoreProgress", "canSync", "cloud_sync", "ibadah_progress"]:
    if token not in cloud:
        fail(f"CloudSyncService token missing: {token}")

for forbidden in ["isPremium", "premium_sync", "required bool isPremium"]:
    if forbidden in cloud:
        fail(f"CloudSyncService still contains Premium-only token: {forbidden}")

auth = (ROOT / "lib/core/services/auth_service.dart").read_text(encoding="utf-8")
for token in ["signInWithGoogle", "signInWithApple", "continueAsGuest"]:
    if token not in auth:
        fail(f"AuthService token missing: {token}")

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
for token in ["AuthService", "CloudSyncService", "ChangeNotifierProxyProvider<AuthService, GamificationService>"]:
    if token not in main:
        fail(f"Provider token missing: {token}")

gamification = (ROOT / "lib/core/services/gamification_service.dart").read_text(encoding="utf-8")
for token in ["syncAuthState", "cloudSyncAvailable", "backupNow", "restoreFromCloudIfNewer", "_scheduleCloudBackup"]:
    if token not in gamification:
        fail(f"Gamification cloud token missing: {token}")

if "syncPremiumState" in gamification:
    fail("GamificationService still contains syncPremiumState")

screen = (ROOT / "lib/features/gamification/presentation/gamification_screen.dart").read_text(encoding="utf-8")
for token in ["cloudSyncFreeActive", "cloudSyncNeedsLogin", "cloudSyncGuestLocalOnly", "syncNow"]:
    if token not in screen:
        fail(f"Gamification UI token missing: {token}")

if "PurchaseService" in screen:
    fail("Gamification screen still depends on PurchaseService for Cloud Sync")

rules = (ROOT / "firestore.rules").read_text(encoding="utf-8") if (ROOT / "firestore.rules").exists() else ""
if "cloud_sync" not in rules:
    fail("Firestore rules missing cloud_sync rule")

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
    fail("Broken imports found:\\n" + "\\n".join(broken))

print("✅ Free Cloud Sync final audit passed.")
