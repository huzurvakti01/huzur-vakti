#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "lib/core/services/hard_wake_service.dart",
    "lib/core/services/biometric_lock_service.dart",
    "lib/core/services/secure_notes_service.dart",
    "lib/features/alarm/presentation/adhan_alarm_screen.dart",
    "lib/features/premium/presentation/secure_notes_screen.dart",
    "lib/features/premium/presentation/premium_audio_library_screen.dart",
    "docs/PREMIUM_ONLY_FEATURES_UPGRADE.md",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in ["sensors_plus:", "local_auth:", "flutter_dynamic_icon:", "path_provider:"]:
    if dep not in pubspec:
        fail(f"Missing dependency: {dep}")

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
for symbol in ["HardWakeService", "BiometricLockService", "SecureNotesService"]:
    if symbol not in main:
        fail(f"Provider missing: {symbol}")

router = (ROOT / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
for route in ["/alarm", "/secure-notes", "/premium-library"]:
    if route not in router:
        fail(f"Route missing: {route}")

settings = (ROOT / "lib/features/settings/presentation/settings_screen.dart").read_text(encoding="utf-8")
for token in ["_toggleHardWake", "_toggleBiometric", "/secure-notes", "/premium-library"]:
    if token not in settings:
        fail(f"Settings integration missing: {token}")

hard_wake = (ROOT / "lib/core/services/hard_wake_service.dart").read_text(encoding="utf-8")
for token in ["requiredShakeCount = 20", "accelerometerEventStream", "math"]:
    if token not in hard_wake:
        fail(f"Hard wake token missing: {token}")

biometric = (ROOT / "lib/core/services/biometric_lock_service.dart").read_text(encoding="utf-8")
for token in ["LocalAuthentication", "authenticate", "premium_required_biometric"]:
    if token not in biometric:
        fail(f"Biometric token missing: {token}")

plist = (ROOT / "ios/Runner/Info.plist").read_text(encoding="utf-8")
if "NSFaceIDUsageDescription" not in plist:
    fail("NSFaceIDUsageDescription missing")

manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
if "android.permission.USE_BIOMETRIC" not in manifest:
    fail("USE_BIOMETRIC permission missing")

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

print("✅ Premium-only features audit passed.")
