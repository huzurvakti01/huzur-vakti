#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "lib/core/services/auth_service.dart",
    "lib/features/auth/presentation/auth_screen.dart",
    "lib/core/services/cloud_sync_service.dart",
    "lib/core/services/gamification_service.dart",
    "docs/FREE_CLOUD_SYNC_AUTH.md",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in ["firebase_auth:", "google_sign_in:", "sign_in_with_apple:", "crypto:", "cloud_firestore:"]:
    if dep not in pubspec:
        fail(f"Missing dependency: {dep}")

auth = (ROOT / "lib/core/services/auth_service.dart").read_text(encoding="utf-8")
for token in ["signInWithGoogle", "signInWithApple", "continueAsGuest", "GoogleAuthProvider", "OAuthProvider('apple.com')"]:
    if token not in auth:
        fail(f"AuthService token missing: {token}")

router = (ROOT / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
for token in ["AuthScreen", "redirect:", "'/auth'", "AuthService"]:
    if token not in router:
        fail(f"Router auth integration missing: {token}")

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
for token in ["AuthService", "ChangeNotifierProxyProvider<AuthService, GamificationService>"]:
    if token not in main:
        fail(f"Provider integration missing: {token}")

cloud = (ROOT / "lib/core/services/cloud_sync_service.dart").read_text(encoding="utf-8")
for token in ["cloud_sync", "backupProgress", "restoreProgress", "user == null || user.isAnonymous"]:
    if token not in cloud:
        fail(f"Free cloud sync token missing: {token}")

if "required bool isPremium" in cloud or "premium_sync" in cloud:
    fail("CloudSyncService still contains premium-only sync logic")

gamification = (ROOT / "lib/core/services/gamification_service.dart").read_text(encoding="utf-8")
for token in ["syncAuthState", "cloudSyncAvailable", "backupNow", "restoreFromCloudIfNewer"]:
    if token not in gamification:
        fail(f"Gamification auth sync token missing: {token}")

if "syncPremiumState" in gamification:
    fail("GamificationService still uses premium sync state")

screen = (ROOT / "lib/features/gamification/presentation/gamification_screen.dart").read_text(encoding="utf-8")
for token in ["cloudSyncFreeActive", "cloudSyncNeedsLogin", "cloudSyncGuestLocalOnly"]:
    if token not in screen:
        fail(f"Cloud sync UI token missing: {token}")

rules = (ROOT / "firestore.rules").read_text(encoding="utf-8") if (ROOT / "firestore.rules").exists() else ""
if "cloud_sync" not in rules:
    fail("Firestore rules missing cloud_sync path")

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
    fail("Broken imports found:\n" + "\n".join(broken))

print("✅ Free cloud sync auth audit passed.")
