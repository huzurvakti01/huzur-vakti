#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    "lib/core/logging/app_logger.dart",
    "lib/core/errors/app_exception.dart",
    "lib/core/errors/error_presenter.dart",
]

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing required error handling file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
if "logger:" not in pubspec:
    fail("logger dependency missing from pubspec.yaml")

print_debug = []
broken_imports = []
catch_without_logger = []
ui_catch_without_presenter = []

for path in (ROOT / "lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    rel = str(path.relative_to(ROOT))

    if "print(" in text or "debugPrint" in text:
        print_debug.append(rel)

    for match in re.finditer(r"import\s+'([^']+)';", text):
        imp = match.group(1)
        if imp.startswith(("package:", "dart:")):
            continue
        target = (path.parent / imp).resolve()
        if not target.exists():
            broken_imports.append(f"{rel} -> {imp}")

    for match in re.finditer(r"\bcatch\s*(?:\([^)]*\))?\s*\{", text):
        block = text[match.start():match.start() + 900]
        if "AppLogger" not in block and "rethrow" not in block:
            line = text[:match.start()].count("\n") + 1
            catch_without_logger.append(f"{rel}:{line}")

    if "/presentation/" in rel and "catch" in text and "ErrorPresenter" not in text:
        ui_catch_without_presenter.append(rel)

if print_debug:
    fail("print/debugPrint usage found:\n" + "\n".join(print_debug))
if broken_imports:
    fail("Broken imports found:\n" + "\n".join(broken_imports))
if catch_without_logger:
    fail("Catch blocks without AppLogger/rethrow found:\n" + "\n".join(catch_without_logger))
if ui_catch_without_presenter:
    fail("UI catch blocks without ErrorPresenter found:\n" + "\n".join(ui_catch_without_presenter))

print("✅ Professional error handling audit passed.")
