#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required_files = [
    "lib/core/services/quran_api_service.dart",
    "lib/core/services/gamification_service.dart",
    "lib/core/services/prayer_api_service.dart",
    "lib/core/services/ads/ad_service.dart",
    "lib/core/services/purchase_service.dart",
    "lib/core/services/finance_rate_service.dart",
    "lib/core/constants/app_strings.dart",
]

for rel in required_files:
    if not (ROOT / rel).exists():
        fail(f"Missing production file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for package in [
    "http:",
    "google_mobile_ads:",
    "in_app_purchase:",
    "firebase_core:",
    "cloud_firestore:",
    "shared_preferences:",
]:
    if package not in pubspec:
        fail(f"Missing package: {package}")

blocked_terms = [
    "TO" + "DO",
    "Du" + "mmy",
    "du" + "mmy",
    "Mo" + "ck",
    "mo" + "ck",
    "De" + "mo",
    "de" + "mo",
]

violations = []
for path in ROOT.rglob("*"):
    if not path.is_file():
        continue
    if path.suffix.lower() not in {".dart", ".md", ".yaml", ".xml", ".plist", ".gradle", ".kt", ".swift", ".py"}:
        continue

    text = path.read_text(encoding="utf-8", errors="ignore")
    for word in blocked_terms:
        if re.search(rf"\b{re.escape(word)}\b", text):
            violations.append(f"{path.relative_to(ROOT)} -> {word}")

if violations:
    fail("Blocked placeholder wording found:\n" + "\n".join(violations))

broken_imports = []
presentation_literals = []

for path in (ROOT / "lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    rel = str(path.relative_to(ROOT))

    for match in re.finditer(r"import\s+'([^']+)';", text):
        imp = match.group(1)
        if imp.startswith(("package:", "dart:")):
            continue
        if not (path.parent / imp).resolve().exists():
            broken_imports.append(f"{rel} -> {imp}")

    if "/presentation/" in rel:
        for match in re.finditer(r"'([^'\\]*(?:\\.[^'\\]*)*)'", text):
            value = match.group(1)
            line = text[:match.start()].count("\n") + 1

            if value.startswith(("package:", "dart:", "../../../", "../../", "../", "/", "assets/", "http", "https")):
                continue
            if len(value) <= 1:
                continue
            if re.fullmatch(r"[A-Za-z0-9_./:-]+", value):
                continue

            presentation_literals.append(f"{rel}:{line} -> {value}")

if broken_imports:
    fail("Broken imports found:\n" + "\n".join(broken_imports))
if presentation_literals:
    fail("Hardcoded presentation strings found:\n" + "\n".join(presentation_literals))

premium = (ROOT / "lib/core/services/purchase_service.dart").read_text(encoding="utf-8")
if "restorePremiumForDebug" in premium:
    fail("Debug premium bypass is still present")

constants = (ROOT / "lib/core/config/app_constants.dart").read_text(encoding="utf-8")
for screen in ["home", "quran", "qibla", "ai", "kids"]:
    if screen not in constants:
        fail(f"Sensitive screen not protected: {screen}")

print("✅ Production audit passed.")
