#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "pubspec.yaml",
    "lib/main.dart",
    "lib/firebase_options.dart",
    "android/app/src/main/AndroidManifest.xml",
    "ios/Runner/Info.plist",
    "firestore.rules",
    "assets/audio/fallback.mp3",
]

FORBIDDEN_TEXT = [
    "TO" + "DO",
    "sk-your",
    "OPENAI_API_KEY=",
]

def fail(msg: str) -> None:
    print(f"❌ {msg}")
    sys.exit(1)

def main() -> None:
    for rel in REQUIRED:
        if not (ROOT / rel).exists():
            fail(f"Missing required file: {rel}")

    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() not in {".dart", ".kt", ".swift", ".xml", ".yaml", ".yml", ".gradle", ".md", ".env", ".plist"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")

        for forbidden in FORBIDDEN_TEXT:
            if forbidden in text and path.name not in {".env.example", "README.md"}:
                fail(f"Forbidden text '{forbidden}' found in {path.relative_to(ROOT)}")

        if path.suffix == ".dart":
            for match in re.finditer(r"import\s+'([^']+)';", text):
                imp = match.group(1)
                if imp.startswith(("package:", "dart:")):
                    continue
                target = (path.parent / imp).resolve()
                if not target.exists():
                    fail(f"Broken import in {path.relative_to(ROOT)} -> {imp}")

    manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
    for permission in [
        "android.permission.INTERNET",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.SCHEDULE_EXACT_ALARM",
    ]:
        if permission not in manifest:
            fail(f"Android permission missing: {permission}")

    info = (ROOT / "ios/Runner/Info.plist").read_text(encoding="utf-8")
    for key in ["NSLocationWhenInUseUsageDescription", "NSSupportsLiveActivities", "UIBackgroundModes"]:
        if key not in info:
            fail(f"iOS Info.plist key missing: {key}")

    print("✅ Release audit passed.")

if __name__ == "__main__":
    main()
