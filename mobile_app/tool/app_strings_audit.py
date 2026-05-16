#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
APP_STRINGS = ROOT / "lib/core/constants/app_strings.dart"

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

if not APP_STRINGS.exists():
    fail("lib/core/constants/app_strings.dart missing")

broken_imports = []
ui_literals = []

for path in (ROOT / "lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    rel = str(path.relative_to(ROOT))

    for match in re.finditer(r"import\s+'([^']+)';", text):
        imp = match.group(1)
        if imp.startswith(("package:", "dart:")):
            continue
        target = (path.parent / imp).resolve()
        if not target.exists():
            broken_imports.append(f"{rel} -> {imp}")

    if "/presentation/" not in rel:
        continue

    for match in re.finditer(r"'([^'\\]*(?:\\.[^'\\]*)*)'", text):
        value = match.group(1)
        line = text[:match.start()].count("\n") + 1

        if value.startswith(("package:", "dart:", "../../../", "../../", "../", "/", "assets/", "http", "https")):
            continue
        if len(value) <= 1:
            continue
        if re.fullmatch(r"[A-Za-z0-9_./:-]+", value):
            continue

        ui_literals.append(f"{rel}:{line} -> {value}")

if broken_imports:
    fail("Broken imports found:\n" + "\n".join(broken_imports))
if ui_literals:
    fail("Hardcoded UI strings found:\n" + "\n".join(ui_literals))

print("✅ AppStrings audit passed.")
