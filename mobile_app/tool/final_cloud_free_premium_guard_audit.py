#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "lib/core/services/auth_service.dart",
    "lib/core/services/cloud_sync_service.dart",
    "lib/core/services/gamification_service.dart",
    "lib/core/services/hard_wake_service.dart",
    "lib/core/services/biometric_lock_service.dart",
    "lib/features/auth/presentation/auth_screen.dart",
    "lib/features/profile/presentation/profile_backup_screen.dart",
    "lib/features/premium/presentation/secure_notes_screen.dart",
    "lib/features/premium/presentation/premium_audio_library_screen.dart",
    "docs/CLOUD_SYNC_FREE_PREMIUM_GUARDS.md",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in ["firebase_auth:", "google_sign_in:", "sign_in_with_apple:", "cloud_firestore:", "shared_preferences:", "local_auth:", "sensors_plus:"]:
    if dep not in pubspec:
        fail(f"Missing dependency: {dep}")

cloud = (ROOT / "lib/core/services/cloud_sync_service.dart").read_text(encoding="utf-8")
for token in ["backupProgress", "restoreProgress", "canSync", "cloud_sync", "ibadah_progress"]:
    if token not in cloud:
        fail(f"CloudSyncService missing token: {token}")

for forbidden in ["isPremium", "premium_sync", "required bool isPremium"]:
    if forbidden in cloud:
        fail(f"CloudSyncService still contains Premium lock: {forbidden}")

auth = (ROOT / "lib/core/services/auth_service.dart").read_text(encoding="utf-8")
for token in ["signInWithGoogle", "signInWithApple", "continueAsGuest"]:
    if token not in auth:
        fail(f"AuthService missing token: {token}")

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
for token in ["AuthService", "CloudSyncService", "ChangeNotifierProxyProvider<AuthService, GamificationService>"]:
    if token not in main:
        fail(f"Provider integration missing: {token}")

gamification = (ROOT / "lib/core/services/gamification_service.dart").read_text(encoding="utf-8")
for token in ["syncAuthState", "cloudSyncAvailable", "backupNow", "restoreFromCloudIfNewer", "_scheduleCloudBackup"]:
    if token not in gamification:
        fail(f"Gamification auth cloud sync missing token: {token}")

if "syncPremiumState" in gamification:
    fail("GamificationService still has Premium-based cloud sync state")

hard_wake = (ROOT / "lib/core/services/hard_wake_service.dart").read_text(encoding="utf-8")
for token in ["setEnabled", "required bool isPremium", "premium_required_hard_wake", "requiredShakeCount = 20"]:
    if token not in hard_wake:
        fail(f"Hard wake Premium guard missing: {token}")

biometric = (ROOT / "lib/core/services/biometric_lock_service.dart").read_text(encoding="utf-8")
for token in ["setEnabled", "required bool isPremium", "premium_required_biometric", "LocalAuthentication"]:
    if token not in biometric:
        fail(f"Biometric Premium guard missing: {token}")

settings = (ROOT / "lib/features/settings/presentation/settings_screen.dart").read_text(encoding="utf-8")
for token in ["_toggleHardWake", "_toggleBiometric", "PurchaseService", "isPremium"]:
    if token not in settings:
        fail(f"Settings Premium guard wiring missing: {token}")

secure_notes = (ROOT / "lib/features/premium/presentation/secure_notes_screen.dart").read_text(encoding="utf-8")
for token in ["PurchaseService", "isPremium", "BiometricLockService", "context.push('/premium')"]:
    if token not in secure_notes:
        fail(f"Secure notes Premium guard missing: {token}")

library = (ROOT / "lib/features/premium/presentation/premium_audio_library_screen.dart").read_text(encoding="utf-8")
for token in ["PurchaseService", "isPremium", "context.push('/premium')", "premiumLibraryLocked"]:
    if token not in library:
        fail(f"Premium audio library guard missing: {token}")

profile = (ROOT / "lib/features/profile/presentation/profile_backup_screen.dart").read_text(encoding="utf-8")
for token in ["SafeBannerAd", "trackCompletedAction", "PurchaseService", "GamificationService"]:
    if token not in profile:
        fail(f"Profile backup monetization/free sync wiring missing: {token}")

router = (ROOT / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
if router.count("path: '/auth'") != 1:
    fail("Auth route duplication detected")
for route in ["/auth", "/profile-backup", "/secure-notes", "/premium-library"]:
    if route not in router:
        fail(f"Route missing: {route}")

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
    fail("Broken imports found:\\n" + "\\n".join(broken))

print("✅ Cloud-free / Premium-guard audit passed.")
