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
    MOBILE / "lib/core/config/app_god_mode_resolver.dart",
    MOBILE / "lib/shared/widgets/dynamic_brand_logo.dart",
    MOBILE / "lib/shared/widgets/dynamic_splash_image.dart",
    MOBILE / "lib/shared/widgets/god_mode_text.dart",
    MOBILE / "lib/main.dart",
    MOBILE / "lib/core/routing/app_router.dart",
    MOBILE / "lib/features/shell/presentation/main_shell.dart",
    MOBILE / "lib/features/home/presentation/home_screen.dart",
    MOBILE / "lib/features/super_app/presentation/super_app_hub_screen.dart",
    MOBILE / "lib/features/support/presentation/assistant_support_hub_screen.dart",
    ROOT / "docs/GOD_MODE_DYNAMIC_CONFIG.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
for token in ["cached_network_image:", "firebase_remote_config:", "cloud_firestore:"]:
    if token not in pubspec:
        fail(f"pubspec dependency missing: {token}")

resolver = (MOBILE / "lib/core/config/app_god_mode_resolver.dart").read_text(encoding="utf-8")
for token in [
    "class AppGodModeResolver",
    "FirebaseFirestore.instance",
    "FirebaseRemoteConfig.instance",
    "app_settings/theme",
    "logoUrl",
    "splashImageUrl",
    "primaryColor",
    "localization_override",
    "isAiEnabled",
    "isWomenCalendarVisible",
    "isSeferiModeActive",
    "isMediaCenterActive",
    "onConfigUpdated",
    "fetchAndActivate",
    "routeEnabled",
    "applyDynamicTheme",
]:
    if token not in resolver:
        fail(f"AppGodModeResolver token missing: {token}")

logo = (MOBILE / "lib/shared/widgets/dynamic_brand_logo.dart").read_text(encoding="utf-8")
for token in [
    "CachedNetworkImage",
    "AppGodModeResolver",
    "resolver.logoUrl",
    "assets/images/logo_main.png",
    "assets/images/logo_white.png",
    "errorWidget",
    "placeholder",
]:
    if token not in logo:
        fail(f"DynamicBrandLogo token missing: {token}")

splash = (MOBILE / "lib/shared/widgets/dynamic_splash_image.dart").read_text(encoding="utf-8")
for token in [
    "CachedNetworkImage",
    "resolver.splashImageUrl",
    "resolver.logoUrl",
    "assets/images/logo_main.png",
    "errorWidget",
]:
    if token not in splash:
        fail(f"DynamicSplashImage token missing: {token}")

god_text = (MOBILE / "lib/shared/widgets/god_mode_text.dart").read_text(encoding="utf-8")
for token in [
    "GodModeText",
    "cloudKey",
    "resolver.text",
    "localization_override",
]:
    if token not in god_text and token != "localization_override":
        fail(f"GodModeText token missing: {token}")

main = (MOBILE / "lib/main.dart").read_text(encoding="utf-8")
for token in [
    "app_god_mode_resolver.dart",
    "final godModeResolver = AppGodModeResolver()",
    "label: 'god_mode_resolver'",
    "ChangeNotifierProvider(create: (_) => godModeResolver)",
    "Consumer4<KidsModeService, PurchaseService, AdService, AppGodModeResolver>",
    "godMode.applyDynamicTheme(AppTheme.light())",
    "godMode.applyDynamicTheme(AppTheme.dark())",
]:
    if token not in main:
        fail(f"main.dart dynamic config token missing: {token}")

router = (MOBILE / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
for token in [
    "AppGodModeResolver",
    "godMode.flags.routeEnabled(location)",
    "return '/'",
]:
    if token not in router:
        fail(f"Router feature flag guard missing: {token}")

shell = (MOBILE / "lib/features/shell/presentation/main_shell.dart").read_text(encoding="utf-8")
for token in [
    "context.watch<AppGodModeResolver>()",
    "godMode.flags.isAiEnabled",
    "_visibleDestinations",
    "NavigationDestination",
]:
    if token not in shell:
        fail(f"MainShell dynamic token missing: {token}")

home = (MOBILE / "lib/features/home/presentation/home_screen.dart").read_text(encoding="utf-8")
for token in [
    "AppGodModeResolver",
    "routeEnabled(a.$3)",
    "GodModeText",
    "dashboardStoriesTitle",
]:
    if token not in home:
        fail(f"Home dynamic token missing: {token}")

hub = (MOBILE / "lib/features/super_app/presentation/super_app_hub_screen.dart").read_text(encoding="utf-8")
for token in [
    "AppGodModeResolver",
    "visibleModules",
    "routeEnabled(module.route)",
]:
    if token not in hub:
        fail(f"SuperAppHub dynamic token missing: {token}")

support = (MOBILE / "lib/features/support/presentation/assistant_support_hub_screen.dart").read_text(encoding="utf-8")
for token in [
    "AppGodModeResolver",
    "visibleItems",
    "routeEnabled(item.route)",
]:
    if token not in support:
        fail(f"AssistantSupportHub dynamic token missing: {token}")

for rel in [
    "lib/features/onboarding/presentation/smart_setup_screen.dart",
    "lib/features/auth/presentation/auth_screen.dart",
]:
    text = (MOBILE / rel).read_text(encoding="utf-8")
    if "DynamicBrandLogo" not in text:
        fail(f"{rel} must use DynamicBrandLogo")

onboarding = (MOBILE / "lib/features/onboarding/presentation/onboarding_screen.dart").read_text(encoding="utf-8")
for token in ["DynamicSplashImage", "GodModeText"]:
    if token not in onboarding:
        fail(f"Onboarding dynamic token missing: {token}")

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

print("✅ God Mode dynamic config audit passed.")
