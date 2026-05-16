#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "mobile_app"
ADMIN = ROOT / "admin_panel"

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required_assets = [
    MOBILE / "assets/images/logo_main.png",
    MOBILE / "assets/images/logo_white.png",
    MOBILE / "assets/images/app_icon.png",
    MOBILE / "assets/images/splash_logo.png",
    ADMIN / "assets/images/logo_main.png",
    ADMIN / "assets/images/logo_white.png",
    ADMIN / "assets/images/app_icon.png",
    ADMIN / "assets/images/splash_logo.png",
]

for path in required_assets:
    if not path.exists() or path.stat().st_size < 1000:
        fail(f"Missing or tiny logo asset: {path.relative_to(ROOT)}")

mobile_pub = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
for token in [
    "flutter_native_splash:",
    "flutter_launcher_icons:",
    "assets/images/",
    "assets/images/splash_logo.png",
    "assets/images/app_icon.png",
    'color: "#06111F"',
    'adaptive_icon_background: "#052F26"',
]:
    if token not in mobile_pub:
        fail(f"Mobile pubspec logo token missing: {token}")

admin_pub = (ADMIN / "pubspec.yaml").read_text(encoding="utf-8")
if "assets/images/" not in admin_pub:
    fail("Admin pubspec assets/images missing")

smart = (MOBILE / "lib/features/onboarding/presentation/smart_setup_screen.dart").read_text(encoding="utf-8")
for token in ["Image.asset", "assets/images/logo_main.png", "width: 120"]:
    if token not in smart:
        fail(f"Smart setup logo token missing: {token}")

auth = (MOBILE / "lib/features/auth/presentation/auth_screen.dart").read_text(encoding="utf-8")
for token in ["Image.asset", "assets/images/logo_main.png", "width: 120"]:
    if token not in auth:
        fail(f"Auth logo token missing: {token}")

admin_shell = (ADMIN / "lib/screens/app_shell.dart").read_text(encoding="utf-8")
for token in ["Image.asset", "assets/images/logo_main.png", "width: 54"]:
    if token not in admin_shell:
        fail(f"Admin shell logo token missing: {token}")

admin_login = (ADMIN / "lib/screens/login_screen.dart").read_text(encoding="utf-8")
for token in ["Image.asset", "assets/images/logo_main.png", "width: 128"]:
    if token not in admin_login:
        fail(f"Admin login logo token missing: {token}")

broken = []
for base in [MOBILE / "lib", ADMIN / "lib"]:
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
    fail("Broken Dart imports found:\\n" + "\\n".join(broken))

print("✅ Logo integration audit passed.")
