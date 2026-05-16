#!/usr/bin/env python3
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "mobile_app"

def fail(message: str) -> None:
    print(f"❌ {message}")
    sys.exit(1)

required = [
    MOBILE / "lib/core/services/data_repository_hub.dart",
    MOBILE / "lib/core/services/prayer_api_service.dart",
    MOBILE / "lib/core/services/quran_api_service.dart",
    MOBILE / "lib/core/services/religious_content_service.dart",
    MOBILE / "lib/core/services/ai_client_service.dart",
    MOBILE / "lib/core/services/ai_chat_service.dart",
    MOBILE / "assets/json/quran_surahs.json",
    MOBILE / "assets/json/quran_tr.json",
    MOBILE / "assets/json/prayer_fallback.json",
    MOBILE / "assets/json/content_fallback.json",
    ROOT / "docs/CONTENT_INTEGRITY_FALLBACK.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
if "assets/json/" not in pubspec:
    fail("pubspec.yaml must include assets/json/")

hub = (MOBILE / "lib/core/services/data_repository_hub.dart").read_text(encoding="utf-8")
for token in [
    "class DataRepositoryHub",
    "hasInternetConnection",
    "fetchPrayerTimesWithFallback",
    "localPrayerTimes",
    "fetchSurahsWithFallback",
    "localSurahList",
    "fetchSurahDetailWithFallback",
    "localSurahDetail",
    "fetchTranslationWithFallback",
    "localTranslation",
    "localDailyContent",
    "appendAiFatwaDisclaimer",
    "aiFatwaDisclaimer",
    "rootBundle.loadString",
    "assets/json/quran_tr.json",
    "assets/json/prayer_fallback.json",
]:
    if token not in hub:
        fail(f"DataRepositoryHub token missing: {token}")

mandatory = "Bu cevap bir yapay zeka asistanı tarafından fıkıh kaynakları taranarak hazırlanmıştır"
for rel in [
    "lib/core/services/data_repository_hub.dart",
    "lib/core/constants/app_strings.dart",
]:
    if mandatory not in (MOBILE / rel).read_text(encoding="utf-8"):
        fail(f"Mandatory fatwa disclaimer missing in {rel}")

for rel in [
    "lib/core/services/ai_client_service.dart",
    "lib/core/services/ai_chat_service.dart",
]:
    text = (MOBILE / rel).read_text(encoding="utf-8")
    if "appendAiFatwaDisclaimer" not in text:
        fail(f"AI disclaimer guard missing in {rel}")

prayer = (MOBILE / "lib/core/services/prayer_api_service.dart").read_text(encoding="utf-8")
for token in [
    "DataRepositoryHub",
    "fetchPrayerTimesWithFallback",
    "api.aladhan.com",
]:
    if token not in prayer:
        fail(f"Prayer fallback token missing: {token}")

quran = (MOBILE / "lib/core/services/quran_api_service.dart").read_text(encoding="utf-8")
for token in [
    "DataRepositoryHub",
    "fetchSurahsWithFallback",
    "fetchSurahDetailWithFallback",
    "fetchTranslationWithFallback",
    "api.alquran.cloud",
    "tr.diyanet",
    "en.sahih",
    "ar.muyassar",
    "fr.hamidullah",
    "ur.jalandhry",
    "id.indonesian",
]:
    if token not in quran:
        fail(f"Quran fallback/token missing: {token}")

religious = (MOBILE / "lib/core/services/religious_content_service.dart").read_text(encoding="utf-8")
for token in [
    "DataRepositoryHub",
    "localDailyContent",
    "_localizedFallback",
    "assets/json",
]:
    if token not in religious:
        fail(f"Religious content fallback token missing: {token}")

quran_tr = json.loads((MOBILE / "assets/json/quran_tr.json").read_text(encoding="utf-8"))
for surah in ["1", "112", "113", "114"]:
    if surah not in quran_tr:
        fail(f"quran_tr.json missing surah {surah}")
    if not quran_tr[surah].get("arabic") or not quran_tr[surah].get("translation"):
        fail(f"quran_tr.json incomplete surah {surah}")

prayer_json = json.loads((MOBILE / "assets/json/prayer_fallback.json").read_text(encoding="utf-8"))
for key in ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]:
    if key not in prayer_json.get("times", {}):
        fail(f"prayer_fallback.json missing {key}")

content = json.loads((MOBILE / "assets/json/content_fallback.json").read_text(encoding="utf-8"))
for code in ["tr", "en", "ar", "fr", "ur", "id"]:
    if code not in content:
        fail(f"content_fallback.json missing {code}")
    for key in ["ayah", "hadith", "dua"]:
        if key not in content[code] or not content[code][key]:
            fail(f"content_fallback.json missing {code}.{key}")

for code in ["tr", "en", "ar", "fr", "ur", "id"]:
    path = MOBILE / "assets/translations" / f"{code}.json"
    data = json.loads(path.read_text(encoding="utf-8"))

    for key in ["calculationMethod", "quran", "toolsCompass", "assistantSupport"]:
        if key not in data or not data[key]:
            fail(f"translation {code}.json missing key {key}")

quality_expectations = {
    "en": ["Salah", "Qur"],
    "tr": ["Namaz", "Kur"],
    "ar": ["الصلاة", "القرآن"],
    "fr": ["salat", "Coran"],
    "ur": ["نماز", "قرآن"],
    "id": ["Salat", "Qur"],
}
for code, fragments in quality_expectations.items():
    raw = json.dumps(json.loads((MOBILE / "assets/translations" / f"{code}.json").read_text(encoding="utf-8")), ensure_ascii=False)
    for fragment in fragments:
        if fragment not in raw:
            fail(f"Islamic terminology fragment '{fragment}' missing in {code}.json")

main = (MOBILE / "lib/main.dart").read_text(encoding="utf-8")
for token in [
    "data_repository_hub.dart",
    "Provider(create: (_) => DataRepositoryHub())",
    "ai_client_service.dart",
    "analytics_service.dart",
    "crash_reporting_service.dart",
]:
    if token not in main:
        fail(f"main.dart integration token missing: {token}")

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

print("✅ Content integrity and offline fallback audit passed.")
