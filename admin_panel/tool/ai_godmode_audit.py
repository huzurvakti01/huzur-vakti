#!/usr/bin/env python3
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    "lib/main.dart",
    "lib/screens/app_shell.dart",
    "lib/screens/dashboard_screen.dart",
    "lib/screens/user_matrix_screen.dart",
    "lib/screens/absolute_moderation_screen.dart",
    "lib/screens/kill_switch_screen.dart",
    "lib/screens/cms_studio_screen.dart",
    "lib/screens/ai_studio_screen.dart",
    "lib/services/ai_autopilot_service.dart",
    "lib/services/functions_service.dart",
    "lib/services/user_matrix_service.dart",
    "functions/index.js",
    "functions/package.json",
    "docs/AI_GODMODE_ARCHITECTURE.md",
]

for rel in required:
    if not (ROOT / rel).exists():
        fail(f"Missing required file: {rel}")

pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
for dep in ["firebase_core:", "firebase_auth:", "cloud_firestore:", "cloud_functions:", "provider:", "google_fonts:"]:
    if dep not in pubspec:
        fail(f"Missing Flutter dependency: {dep}")

pkg = (ROOT / "functions/package.json").read_text(encoding="utf-8")
for dep in ["firebase-admin", "firebase-functions", "node-fetch"]:
    if dep not in pkg:
        fail(f"Missing functions dependency: {dep}")

functions = (ROOT / "functions/index.js").read_text(encoding="utf-8")
for fn in [
    "assertGodModeAdmin",
    "listAuthUsers",
    "updateUserGodMode",
    "hardDeleteUser",
    "resetUserPassword",
    "banUserDevice",
    "publishKillSwitchConfig",
    "analyzeDuaText",
    "aiModerateDuaOnCreate",
    "generateDailyIslamicContent",
    "scheduledDailyIslamicContent",
    "generateDashboardAiSummary",
]:
    if fn not in functions:
        fail(f"Cloud Function missing: {fn}")

for token in ["OPENAI_API_KEY", "response_format", "toxicity_score", "toxicity > 0.8", "ai_action_logs", "daily_content"]:
    if token not in functions:
        fail(f"AI backend token missing: {token}")

node_check = subprocess.run(
    ["node", "--check", "functions/index.js"],
    cwd=ROOT,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
)
if node_check.returncode != 0:
    fail("functions/index.js syntax check failed:\n" + node_check.stdout)

main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
for token in ["AiAutopilotService", "FunctionsService", "AuthService", "UserMatrixService", "KillSwitchService"]:
    if token not in main:
        fail(f"main.dart provider missing: {token}")

shell = (ROOT / "lib/screens/app_shell.dart").read_text(encoding="utf-8")
if shell.count("NavigationRailDestination") != 6:
    fail("NavigationRail destination count must be 6")
if "AiStudioScreen" not in shell or "AI Studio" not in shell:
    fail("AI Studio missing from shell")

dashboard = (ROOT / "lib/screens/dashboard_screen.dart").read_text(encoding="utf-8")
for token in ["AI Anomali ve İstatistik Asistanı", "generateDashboardSummary", "AI Özet Üret"]:
    if token not in dashboard:
        fail(f"Dashboard AI summary missing: {token}")

ai_studio = (ROOT / "lib/screens/ai_studio_screen.dart").read_text(encoding="utf-8")
for token in ["generateDailyContent", "watchAiLogs", "watchDailyContent", "AI İşlem Geçmişi", "Tek Tuşla Günlük İçerik Üret"]:
    if token not in ai_studio:
        fail(f"AI Studio feature missing: {token}")

moderation = (ROOT / "lib/screens/absolute_moderation_screen.dart").read_text(encoding="utf-8")
for token in ["AI Analiz", "analyzeDua", "Author UID", "updateDua", "deleteDua"]:
    if token not in moderation:
        fail(f"Moderation feature missing: {token}")

users = (ROOT / "lib/screens/user_matrix_screen.dart").read_text(encoding="utf-8")
for token in ["resetPassword", "banDevice", "Hard Delete", "Premium Bitiş Tarihi", "Banlı Device ID"]:
    if token not in users:
        fail(f"User Matrix God Mode feature missing: {token}")

kill = (ROOT / "lib/screens/kill_switch_screen.dart").read_text(encoding="utf-8")
for token in ["Zorunlu Güncelleme", "Min. Versiyon Kodu", "AI Sohbet", "Zikirmatik", "Cloud Sync"]:
    if token not in kill:
        fail(f"Kill Switch feature missing: {token}")

cms = (ROOT / "lib/screens/cms_studio_screen.dart").read_text(encoding="utf-8")
for token in ["Günün Ayeti", "Günün Hadisi", "Hakkımızda", "upsertContent"]:
    if token not in cms:
        fail(f"CMS feature missing: {token}")

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

for blocked in ["TODO", "dummy", "mock"]:
    hits = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".dart", ".js", ".json", ".yaml", ".md", ".rules"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if re.search(rf"\b{re.escape(blocked)}\b", text, re.IGNORECASE):
            hits.append(str(path.relative_to(ROOT)))
    if hits:
        fail(f"Blocked placeholder term found: {blocked}\n" + "\n".join(hits))

print("✅ AI God Mode Admin audit passed.")
