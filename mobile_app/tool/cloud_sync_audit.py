#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    "lib/core/services/cloud_sync_service.dart",
    "lib/core/services/gamification_service.dart",
    "lib/core/models/qaza_progress.dart",
    "lib/features/gamification/presentation/gamification_screen.dart",
    "docs/PREMIUM_CLOUD_SYNC.md",
]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in ["cloud_firestore:", "firebase_auth:", "shared_preferences:"]:
    if dep not in pubspec:
        fail(f"Missing dependency: {dep}")

cloud = (ROOT / "lib/core/services/cloud_sync_service.dart").read_text(encoding="utf-8")
for token in ["backupProgress", "restoreProgress", "premium_sync", "ibadah_progress", "signInAnonymously"]:
    if token not in cloud:
        fail(f"CloudSyncService token missing: {token}")

gamification = (ROOT / "lib/core/services/gamification_service.dart").read_text(encoding="utf-8")
for token in ["syncPremiumState", "restoreFromCloudIfNewer", "backupNow", "SharedPreferences", "_scheduleCloudBackup"]:
    if token not in gamification:
        fail(f"Gamification cloud integration missing: {token}")

model = (ROOT / "lib/core/models/qaza_progress.dart").read_text(encoding="utf-8")
for token in ["streakDays", "lastActivityDate", "updatedAt", "toMap", "fromMap"]:
    if token not in model:
        fail(f"QazaProgress field/method missing: {token}")

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
for token in ["CloudSyncService", "ChangeNotifierProxyProvider<PurchaseService, GamificationService>"]:
    if token not in main:
        fail(f"Provider integration missing: {token}")

screen = (ROOT / "lib/features/gamification/presentation/gamification_screen.dart").read_text(encoding="utf-8")
for token in ["cloudSyncing", "lastCloudSyncAt", "cloudSyncLocalOnly", "syncNow"]:
    if token not in screen:
        fail(f"Cloud sync UI token missing: {token}")

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
    fail("Broken Dart imports:\n" + "\n".join(broken))

print("✅ Premium cloud sync audit passed.")
