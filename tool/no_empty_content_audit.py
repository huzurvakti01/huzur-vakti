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
    MOBILE / "lib/core/services/gallery_service.dart",
    MOBILE / "lib/features/gallery/presentation/wallpaper_gallery_screen.dart",
    MOBILE / "lib/core/services/greeting_card_service.dart",
    MOBILE / "lib/features/tools/presentation/greeting_card_screen.dart",
    MOBILE / "lib/core/services/religious_content_service.dart",
    MOBILE / "lib/features/home/presentation/home_screen.dart",
    MOBILE / "lib/core/routing/app_router.dart",
    ROOT / "docs/NO_EMPTY_CONTENT_WALLPAPER.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

gallery = (MOBILE / "lib/core/services/gallery_service.dart").read_text(encoding="utf-8")
for token in [
    "api.unsplash.com",
    "images.unsplash.com",
    "fetchIslamicWallpapers",
    "saveImageToDevice",
    "getApplicationDocumentsDirectory",
    "wallpaper_save_failed",
]:
    if token not in gallery:
        fail(f"Gallery service token missing: {token}")

gallery_screen = (MOBILE / "lib/features/gallery/presentation/wallpaper_gallery_screen.dart").read_text(encoding="utf-8")
for token in [
    "_openImageActions",
    "_saveToDevice",
    "wallpaperSaveToDevice",
    "wallpaperMakeCard",
    "context.push('/greeting-card', extra: image.imageUrl)",
    "onTap: () => _openImageActions(image)",
]:
    if token not in gallery_screen:
        fail(f"Wallpaper action token missing: {token}")

greeting_service = (MOBILE / "lib/core/services/greeting_card_service.dart").read_text(encoding="utf-8")
for token in [
    "backgroundUrl",
    "http.get",
    "decodeImage",
    "copyResizeCropSquare",
    "huzur_vakti_card_",
]:
    if token not in greeting_service:
        fail(f"Greeting card background token missing: {token}")

greeting_screen = (MOBILE / "lib/features/tools/presentation/greeting_card_screen.dart").read_text(encoding="utf-8")
for token in [
    "initialImageUrl",
    "widget.initialImageUrl",
    "Image.network(widget.initialImageUrl!",
    "backgroundUrl: widget.initialImageUrl",
]:
    if token not in greeting_screen:
        fail(f"Greeting card screen token missing: {token}")

router = (MOBILE / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
if "GreetingCardScreen(initialImageUrl: state.extra as String?)" not in router:
    fail("GoRouter must pass wallpaper URL to greeting card screen")

religious = (MOBILE / "lib/core/services/religious_content_service.dart").read_text(encoding="utf-8")
for token in [
    "DashboardReligiousContent",
    "fetchDashboardContent",
    "api.alquran.cloud",
    "api.hadith.gading.dev",
    "diyanet.gov.tr",
    "fallback",
    "translationEditionForLocale",
]:
    if token not in religious:
        fail(f"Religious content service token missing: {token}")

home = (MOBILE / "lib/features/home/presentation/home_screen.dart").read_text(encoding="utf-8")
for token in [
    "ReligiousContentService",
    "fetchDashboardContent(context.locale.languageCode)",
    "ReligiousContentService.fallback",
    "item.source",
    "context.push(item.route)",
]:
    if token not in home:
        fail(f"Home live content token missing: {token}")

main = (MOBILE / "lib/main.dart").read_text(encoding="utf-8")
if "Provider(create: (_) => ReligiousContentService())" not in main:
    fail("ReligiousContentService provider missing")

strings = (MOBILE / "lib/core/constants/app_strings.dart").read_text(encoding="utf-8")
for token in [
    "wallpaperSaveToDevice",
    "wallpaperMakeCard",
    "wallpaperSavedToDevice",
    "religiousContentAyahSource",
    "religiousContentHadithSource",
    "religiousContentKhutbahSource",
]:
    if token not in strings:
        fail(f"AppStrings token missing: {token}")

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

for blocked in ["TODO", "Demo", "dummy", "mock"]:
    hits = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".dart", ".js", ".yaml", ".yml", ".json", ".xml", ".plist", ".md", ".rules", ".kt", ".swift"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if re.search(rf"\b{re.escape(blocked)}\b", text, re.IGNORECASE):
            hits.append(str(path.relative_to(ROOT)))
    if hits:
        fail(f"Blocked placeholder term found: {blocked}\n" + "\n".join(hits))

print("✅ No-empty content and wallpaper audit passed.")
