#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "lib/features/profile/presentation/profile_backup_screen.dart",
    "lib/core/services/ads/ad_service.dart",
    "lib/features/auth/presentation/auth_screen.dart",
    "lib/core/routing/app_router.dart",
    "docs/BACKUP_AD_MONETIZATION.md",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

ad_service = (ROOT / "lib/core/services/ads/ad_service.dart").read_text(encoding="utf-8")
for token in ["trackCompletedAction", "adsDisabled(context)", "showInterstitialIfReady"]:
    if token not in ad_service:
        fail(f"AdService token missing: {token}")

profile = (ROOT / "lib/features/profile/presentation/profile_backup_screen.dart").read_text(encoding="utf-8")
for token in [
    "SafeBannerAd",
    "screenKey",
    "trackCompletedAction",
    "PurchaseService",
    "_backupNow",
    "_loginWithGoogle",
    "_loginWithApple",
]:
    if token not in profile:
        fail(f"ProfileBackupScreen integration missing: {token}")

if "SafeBannerAd(screenKey: screenKey)" not in profile:
    fail("ProfileBackupScreen bottom banner missing")

auth = (ROOT / "lib/features/auth/presentation/auth_screen.dart").read_text(encoding="utf-8")
for token in ["AdService", "PurchaseService", "trackCompletedAction"]:
    if token not in auth:
        fail(f"AuthScreen ad trigger missing: {token}")

router = (ROOT / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
if "/profile-backup" not in router or "ProfileBackupScreen" not in router:
    fail("Profile backup route missing")

if router.count("path: '/auth'") != 1:
    fail("Auth route duplication detected")

settings = (ROOT / "lib/features/settings/presentation/settings_screen.dart").read_text(encoding="utf-8")
if "/profile-backup" not in settings:
    fail("Settings entry for profile backup missing")

constants = (ROOT / "lib/core/config/app_constants.dart").read_text(encoding="utf-8")
if "profile_backup" in constants:
    fail("profile_backup must not be marked as sensitive/no-ad screen")

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

print("✅ Backup ad monetization audit passed.")
