#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "mobile_app"
ADMIN = ROOT / "admin_panel"

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    ROOT / "firestore.rules",
    MOBILE / "lib/core/services/ai_client_service.dart",
    MOBILE / "lib/core/services/ai_chat_service.dart",
    MOBILE / "lib/core/services/analytics_service.dart",
    MOBILE / "lib/core/services/crash_reporting_service.dart",
    MOBILE / "lib/main.dart",
    ADMIN / "functions/index.js",
    ADMIN / "functions/package.json",
    ROOT / "docs/SECURITY_HARDENING.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

rules = (ROOT / "firestore.rules").read_text(encoding="utf-8")
for token in [
    "rules_version = '2'",
    "function isAdmin()",
    "request.auth.token.isAdmin == true",
    "match /users/{uid}",
    "match /tickets/{ticketId}",
    "match /support_tickets/{ticketId}",
    "match /dualar/{duaId}",
    "match /ai_audit_logs/{logId}",
    "allow read, write: if false",
]:
    if token not in rules:
        fail(f"Firestore rules token missing: {token}")

for forbidden in [
    "allow read, write: if true",
    "allow write: if true",
]:
    if forbidden in rules:
        fail(f"Insecure Firestore rule found: {forbidden}")

ai_client = (MOBILE / "lib/core/services/ai_client_service.dart").read_text(encoding="utf-8")
for token in [
    "OPENAI_PROXY_CHAT_ENDPOINT",
    "FirebaseAuth.instance",
    "getIdToken(true)",
    "Authorization': 'Bearer $token'",
    "PurchaseService",
    "AnalyticsService",
    "rate_limited",
    "AI proxy request failed",
]:
    if token not in ai_client:
        fail(f"AiClientService token missing: {token}")

for forbidden in [
    "OPENAI_API_KEY",
    "api.openai.com",
    "sk-",
]:
    if forbidden in ai_client:
        fail(f"AiClientService contains forbidden direct OpenAI token: {forbidden}")

ai_chat = (MOBILE / "lib/core/services/ai_chat_service.dart").read_text(encoding="utf-8")
for token in [
    "AiClientService",
    "_secureClient.sendMessage",
    "freeDailyLimit",
    "ai_daily_limit_exceeded",
]:
    if token not in ai_chat:
        fail(f"AiChatService secure wrapper token missing: {token}")

for forbidden in [
    "package:http",
    "flutter_dotenv",
    "api.openai.com",
    "OPENAI_API_KEY",
]:
    if forbidden in ai_chat:
        fail(f"AiChatService must not contain fallback direct network/OpenAI path: {forbidden}")

analytics = (MOBILE / "lib/core/services/analytics_service.dart").read_text(encoding="utf-8")
for token in [
    "FirebaseAnalytics.instance",
    "logAppOpen",
    "logScreenView",
    "logAiMessage",
]:
    if token not in analytics:
        fail(f"AnalyticsService token missing: {token}")

crash = (MOBILE / "lib/core/services/crash_reporting_service.dart").read_text(encoding="utf-8")
for token in [
    "FirebaseCrashlytics.instance",
    "FlutterError.onError",
    "PlatformDispatcher.instance.onError",
    "recordError",
    "setCrashlyticsCollectionEnabled",
]:
    if token not in crash:
        fail(f"CrashReportingService token missing: {token}")

main = (MOBILE / "lib/main.dart").read_text(encoding="utf-8")
for token in [
    "CrashReportingService",
    "AnalyticsService",
    "AiClientService",
    "ProxyProvider2<PurchaseService, AnalyticsService, AiClientService>",
    "ProxyProvider<AiClientService, AiChatService>",
    "label: 'crashlytics'",
    "label: 'analytics_app_open'",
]:
    if token not in main:
        fail(f"main.dart security bootstrap token missing: {token}")

pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
for token in [
    "firebase_crashlytics:",
    "firebase_analytics:",
]:
    if token not in pubspec:
        fail(f"pubspec missing dependency: {token}")

functions = (ADMIN / "functions/index.js").read_text(encoding="utf-8")
for token in [
    "onRequest",
    "openAiChatProxy",
    "verifyMobileBearer",
    "enforceAiRateLimit",
    "current >= 5",
    "writeAiAuditLog",
    "ai_audit_logs",
    "OPENAI_API_KEY",
    "gpt-4o",
    "setAdminClaim",
    "setCustomUserClaims",
    "request.auth.token.isAdmin",
    "aiModerateDuaOnCreate",
    "generateDailyIslamicContent",
]:
    if token not in functions:
        fail(f"Cloud Functions token missing: {token}")

if "require(" in functions:
    fail("Cloud Functions file mixes CommonJS require with ESM imports")

package = (ADMIN / "functions/package.json").read_text(encoding="utf-8")
for token in [
    '"type": "module"',
    '"node-fetch"',
    '"firebase-admin"',
    '"firebase-functions"',
]:
    if token not in package:
        fail(f"Functions package token missing: {token}")

mobile_openai_leaks = []
for path in (MOBILE / "lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    if "OPENAI_API_KEY" in text or "api.openai.com" in text or "sk-" in text:
        mobile_openai_leaks.append(str(path.relative_to(ROOT)))

if mobile_openai_leaks:
    fail("Mobile OpenAI direct references found:\n" + "\n".join(mobile_openai_leaks))

broken = []
for base in [MOBILE / "lib", ADMIN / "lib"]:
    for path in base.rglob("*.dart"):
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

print("✅ Security hardening audit passed.")
