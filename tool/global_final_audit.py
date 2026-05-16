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
    MOBILE / "lib/features/media/presentation/media_center_screen.dart",
    MOBILE / "lib/core/services/media_center_service.dart",
    MOBILE / "lib/features/quran/presentation/quran_screen.dart",
    MOBILE / "lib/core/services/quran_api_service.dart",
    MOBILE / "lib/core/services/quran_audio_service.dart",
    MOBILE / "lib/features/tools/presentation/prayer_dnd_screen.dart",
    MOBILE / "lib/features/traveler/presentation/traveler_mode_screen.dart",
    MOBILE / "lib/features/women/presentation/women_calendar_screen.dart",
    MOBILE / "lib/features/ai/presentation/ai_chat_screen.dart",
    MOBILE / "lib/core/services/ai_chat_service.dart",
    MOBILE / "lib/features/support/presentation/helpdesk_screen.dart",
    MOBILE / "lib/core/services/helpdesk_service.dart",
    MOBILE / "lib/core/services/revenuecat_service.dart",
    MOBILE / "lib/features/premium/presentation/premium_screen.dart",
    MOBILE / "lib/widgets/dashboard_native_ad.dart",
    MOBILE / "lib/core/services/ads/ad_service.dart",
    MOBILE / "lib/core/services/consent_service.dart",
    MOBILE / "lib/features/alarm/presentation/adhan_alarm_screen.dart",
    MOBILE / "lib/features/premium/presentation/secure_notes_screen.dart",
    ADMIN / "lib/main.dart",
    ADMIN / "lib/screens/app_shell.dart",
    ADMIN / "lib/screens/ai_studio_screen.dart",
    ADMIN / "lib/screens/user_matrix_screen.dart",
    ADMIN / "lib/screens/kill_switch_screen.dart",
    ADMIN / "lib/screens/support_tickets_screen.dart",
    ADMIN / "functions/index.js",
    ROOT / "docs/GLOBAL_FINAL_DELIVERY.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

media = (MOBILE / "lib/features/media/presentation/media_center_screen.dart").read_text(encoding="utf-8")
media_service = (MOBILE / "lib/core/services/media_center_service.dart").read_text(encoding="utf-8")
for token in ["YoutubePlayer", "MediaCenterService", "PurchaseService"]:
    if token not in media:
        fail(f"Media screen token missing: {token}")
for token in ["just_audio", "quran_radio", "makkah_live", "madinah_live", "playRadio"]:
    if token not in media_service:
        fail(f"Media service token missing: {token}")

quran_service = (MOBILE / "lib/core/services/quran_api_service.dart").read_text(encoding="utf-8")
for token in [
    "api.alquran.cloud",
    "tr.diyanet",
    "en.sahih",
    "ar.muyassar",
    "fr.hamidullah",
    "ur.jalandhry",
    "id.indonesian",
    "ar.alafasy",
    "fetchSurahAudioAlafasy",
]:
    if token not in quran_service:
        fail(f"Quran service token missing: {token}")

quran_screen = (MOBILE / "lib/features/quran/presentation/quran_screen.dart").read_text(encoding="utf-8")
for token in ["fetchSurahTranslationForLocale", "context.locale.languageCode", "QuranAudioService", "quranAudioPlay"]:
    if token not in quran_screen:
        fail(f"Quran screen token missing: {token}")

dnd = (MOBILE / "lib/features/tools/presentation/prayer_dnd_screen.dart").read_text(encoding="utf-8")
for token in ["PrayerDndService", "activateForPrayerWindow", "SafeBannerAd"]:
    if token not in dnd:
        fail(f"DND screen token missing: {token}")

traveler = (MOBILE / "lib/features/traveler/presentation/traveler_mode_screen.dart").read_text(encoding="utf-8")
for token in ["TravelerModeService", "saveCurrentAsHome", "active"]:
    if token not in traveler:
        fail(f"Traveler screen token missing: {token}")

women = (MOBILE / "lib/features/women/presentation/women_calendar_screen.dart").read_text(encoding="utf-8")
for token in ["WomenCalendarService", "worshipPausedToday", "save"]:
    if token not in women:
        fail(f"Women calendar token missing: {token}")

ai_service = (MOBILE / "lib/core/services/ai_chat_service.dart").read_text(encoding="utf-8")
for token in ["freeDailyLimit", "languageCode", "'model': 'gpt-4o'", "isPremium", "OPENAI_PROXY_CHAT_ENDPOINT"]:
    if token not in ai_service:
        fail(f"AI service token missing: {token}")

ai_screen = (MOBILE / "lib/features/ai/presentation/ai_chat_screen.dart").read_text(encoding="utf-8")
for token in ["context.locale.languageCode", "aiDailyLimit", "upgradeToPremium"]:
    if token not in ai_screen:
        fail(f"AI screen token missing: {token}")

helpdesk_service = (MOBILE / "lib/core/services/helpdesk_service.dart").read_text(encoding="utf-8")
helpdesk_screen = (MOBILE / "lib/features/support/presentation/helpdesk_screen.dart").read_text(encoding="utf-8")
for token in ["support_tickets", "createTicket", "FirebaseFirestore"]:
    if token not in helpdesk_service:
        fail(f"Helpdesk service token missing: {token}")
for token in ["HelpdeskService", "helpdeskSend", "trackButtonTap"]:
    if token not in helpdesk_screen:
        fail(f"Helpdesk screen token missing: {token}")

revenue = (MOBILE / "lib/core/services/revenuecat_service.dart").read_text(encoding="utf-8")
for token in ["Purchases.configure", "getOfferings", "purchasePackage", "restorePurchases", "entitlements.active"]:
    if token not in revenue:
        fail(f"RevenueCat token missing: {token}")

premium = (MOBILE / "lib/features/premium/presentation/premium_screen.dart").read_text(encoding="utf-8")
for token in ["premium_monthly", "premium_yearly", "premium_lifetime", "purchase"]:
    if token not in premium:
        fail(f"Premium paywall token missing: {token}")

ads = (MOBILE / "lib/core/services/ads/ad_service.dart").read_text(encoding="utf-8")
for token in ["interstitial", "nativeUnitId", "isPremium", "globallyDisabled", "showInterstitialIfReady"]:
    if token not in ads:
        fail(f"Ad service token missing: {token}")

native_ad = (MOBILE / "lib/widgets/dashboard_native_ad.dart").read_text(encoding="utf-8")
for token in ["NativeAd", "AdWidget", "PurchaseService", "SizedBox.shrink"]:
    if token not in native_ad:
        fail(f"Dashboard NativeAd token missing: {token}")

consent = (MOBILE / "lib/core/services/consent_service.dart").read_text(encoding="utf-8")
for token in ["ConsentInformation.instance.requestConsentInfoUpdate", "ConsentForm.loadAndShowConsentFormIfRequired", "showPrivacyOptionsForm"]:
    if token not in consent:
        fail(f"UMP token missing: {token}")

alarm = (MOBILE / "lib/features/alarm/presentation/adhan_alarm_screen.dart").read_text(encoding="utf-8")
for token in ["HardWakeService", "requiredShakeCount", "HardWakeChallengeMode.shake", "HardWakeChallengeMode.math"]:
    if token not in alarm:
        fail(f"Hard wake alarm token missing: {token}")

secure = (MOBILE / "lib/features/premium/presentation/secure_notes_screen.dart").read_text(encoding="utf-8")
for token in ["BiometricLockService", "authenticate", "upgradeToPremium"]:
    if token not in secure:
        fail(f"Biometric lock token missing: {token}")

for code in ["tr", "en", "ar", "fr", "ur", "id"]:
    if not (MOBILE / "assets" / "translations" / f"{code}.json").exists():
        fail(f"Missing translation file: {code}.json")

router = (MOBILE / "lib/core/routing/app_router.dart").read_text(encoding="utf-8")
for token in ["/language-country-setup", "/quran", "/tools", "/assistant-support", "/helpdesk"]:
    if token not in router:
        fail(f"Route missing: {token}")

admin_shell = (ADMIN / "lib/screens/app_shell.dart").read_text(encoding="utf-8")
for token in ["UserMatrixScreen", "AiStudioScreen", "KillSwitchScreen", "SupportTicketsScreen"]:
    if token not in admin_shell:
        fail(f"Admin shell token missing: {token}")

functions = (ADMIN / "functions/index.js").read_text(encoding="utf-8")
for token in [
    "OPENAI_API_KEY",
    "aiModerateDuaOnCreate",
    "toxicity_score",
    "generateDailyIslamicContent",
    "generateDashboardAiSummary",
    "publishKillSwitchConfig",
    "banUserDevice",
]:
    if token not in functions:
        fail(f"Admin Cloud Function token missing: {token}")

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

print("✅ Global Final audit passed.")
