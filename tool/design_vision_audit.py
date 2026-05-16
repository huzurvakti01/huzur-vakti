#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "mobile_app"

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    MOBILE / "lib/core/theme/app_theme.dart",
    MOBILE / "lib/features/home/presentation/home_screen.dart",
    MOBILE / "lib/features/shell/presentation/main_shell.dart",
    MOBILE / "lib/shared/widgets/glass_card.dart",
    ROOT / "docs/DESIGN_VISION_AUDIT.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing file: {path.relative_to(ROOT)}")

theme = (MOBILE / "lib/core/theme/app_theme.dart").read_text(encoding="utf-8")
for token in [
    "nightBlue",
    "mysticBlue",
    "glassWhite",
    "CupertinoPageTransitionsBuilder",
    "NavigationBarThemeData",
    "gold",
]:
    if token not in theme:
        fail(f"Theme vision token missing: {token}")

shell = (MOBILE / "lib/features/shell/presentation/main_shell.dart").read_text(encoding="utf-8")
for token in [
    "extendBody: true",
    "ClipRRect",
    "AppTheme.nightBlue.withOpacity(.86)",
    "navHome",
    "navQuranHub",
    "navToolsCompass",
    "navAssistantSupport",
]:
    if token not in shell:
        fail(f"Shell design token missing: {token}")
if shell.count("NavigationDestination") != 4:
    fail("Bottom navigation must have exactly four tabs")

home = (MOBILE / "lib/features/home/presentation/home_screen.dart").read_text(encoding="utf-8")
for token in [
    "CustomPaint",
    "_PrayerRingPainter",
    "SweepGradient",
    "math.sin",
    "wavePath",
    "_InspirationStories",
    "dashboardAyahCard",
    "dashboardHadithCard",
    "dashboardDuaCard",
    "DashboardNativeAd",
    "AppTheme.nightBlue",
]:
    if token not in home:
        fail(f"Home design token missing: {token}")

strings = (MOBILE / "lib/core/constants/app_strings.dart").read_text(encoding="utf-8")
for token in [
    "dashboardAyahText",
    "dashboardHadithText",
    "dashboardDuaText",
    "dashboardStoriesTitle",
]:
    if token not in strings:
        fail(f"Dashboard story string missing: {token}")

glass = (MOBILE / "lib/shared/widgets/glass_card.dart").read_text(encoding="utf-8")
for token in ["BackdropFilter", "ImageFilter.blur", "borderRadius: BorderRadius.circular(30)", "boxShadow"]:
    if token not in glass:
        fail(f"Glass card token missing: {token}")

broken = []
for path in (MOBILE / "lib").rglob("*.dart"):
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

print("✅ Design vision audit passed.")
