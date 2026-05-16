#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    "lib/widgets/dashboard_native_ad.dart",
    "lib/features/home/presentation/home_screen.dart",
    "lib/core/services/ads/ad_service.dart",
    "lib/core/constants/app_strings.dart",
    "docs/DASHBOARD_NATIVE_AD.md",
]

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

widget = (ROOT / "lib/widgets/dashboard_native_ad.dart").read_text(encoding="utf-8")
for token in [
    "NativeAd",
    "AdWidget",
    "NativeTemplateStyle",
    "TemplateType.medium",
    "PurchaseService",
    "AdService",
    "globallyDisabled",
    "SizedBox.shrink",
    "borderRadius: BorderRadius.circular(16)",
    "AppTheme.emerald",
]:
    if token not in widget:
        fail(f"DashboardNativeAd token missing: {token}")

home = (ROOT / "lib/features/home/presentation/home_screen.dart").read_text(encoding="utf-8")
for token in ["dashboard_native_ad.dart", "const DashboardNativeAd()", "_QuickActions()", "_PrayerListCard()"]:
    if token not in home:
        fail(f"Home integration missing: {token}")

if home.index("_QuickActions()") > home.index("const DashboardNativeAd()"):
    fail("Native ad must be placed after quick actions")
if home.index("const DashboardNativeAd()") > home.index("_PrayerListCard()"):
    fail("Native ad must be placed before prayer list")

ad_service = (ROOT / "lib/core/services/ads/ad_service.dart").read_text(encoding="utf-8")
for token in ["nativeUnitId", "ADMOB_ANDROID_NATIVE_ID", "ADMOB_IOS_NATIVE_ID", "2247696110", "3986624511"]:
    if token not in ad_service:
        fail(f"AdService native unit token missing: {token}")

strings = (ROOT / "lib/core/constants/app_strings.dart").read_text(encoding="utf-8")
for token in ["sponsored", "dashboardNativeAdLoading", "dashboardNativeAdButton"]:
    if token not in strings:
        fail(f"AppStrings token missing: {token}")

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

print("✅ Dashboard Native Ad audit passed.")
