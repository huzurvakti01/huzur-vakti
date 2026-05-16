#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "lib/core/services/ai_chat_service.dart",
    "lib/core/services/app_icon_service.dart",
    "lib/features/premium/presentation/app_icon_screen.dart",
    "lib/core/services/audio/adhan_audio_service.dart",
    "docs/PREMIUM_MONETIZATION_UPGRADE.md",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in ["flutter_dynamic_icon:", "path_provider:", "shared_preferences:", "in_app_purchase:"]:
    if dep not in pubspec:
        fail(f"Missing dependency: {dep}")

ai = (ROOT / "lib/core/services/ai_chat_service.dart").read_text(encoding="utf-8")
for token in ["freeDailyLimit = 3", "SharedPreferences", "ai_daily_limit_exceeded"]:
    if token not in ai:
        fail(f"AI limit token missing: {token}")

adhan = (ROOT / "lib/core/services/audio/adhan_audio_service.dart").read_text(encoding="utf-8")
for token in ["downloadForPremium", "getApplicationDocumentsDirectory", "premium_required_adhan_download", "setFilePath"]:
    if token not in adhan:
        fail(f"Adhan premium download token missing: {token}")

settings = (ROOT / "lib/features/settings/presentation/settings_screen.dart").read_text(encoding="utf-8")
for token in ["_downloadAudio", "premiumAdhanDownloadLocked", "'/app-icon'"]:
    if token not in settings:
        fail(f"Settings integration missing: {token}")

router = (ROOT / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
if "AppIconScreen" not in router or "/app-icon" not in router:
    fail("App icon route missing")

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
for symbol in ["AiChatService", "AppIconService"]:
    if symbol not in main:
        fail(f"Provider missing: {symbol}")

plist = (ROOT / "ios/Runner/Info.plist").read_text(encoding="utf-8")
for icon in ["CFBundleAlternateIcons", "GoldIcon", "DarkIcon"]:
    if icon not in plist:
        fail(f"iOS alternate icon config missing: {icon}")

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

print("✅ Premium monetization audit passed.")
