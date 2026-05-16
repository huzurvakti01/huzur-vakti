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
    MOBILE / "android/app/src/main/kotlin/com/huzurvakti/app/MainActivity.kt",
    MOBILE / "android/app/src/main/res/layout/native_ad_glass.xml",
    MOBILE / "android/app/src/main/res/drawable/native_ad_glass_background.xml",
    MOBILE / "android/app/src/main/res/drawable/native_ad_cta_background.xml",
    MOBILE / "ios/Runner/AppDelegate.swift",
    MOBILE / "ios/Runner/HuzurGlassNativeAdFactory.swift",
    MOBILE / "lib/widgets/dashboard_native_ad.dart",
    MOBILE / "lib/core/services/premium_secure_storage_service.dart",
    MOBILE / "lib/core/services/revenuecat_service.dart",
    MOBILE / "lib/core/services/purchase_service.dart",
    MOBILE / "lib/core/services/auth_service.dart",
    MOBILE / "lib/core/services/ad_consent_service.dart",
    MOBILE / "lib/features/settings/presentation/settings_screen.dart",
    ROOT / "docs/NATIVE_MONETIZATION_INTEGRATION.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
for token in ["flutter_secure_storage:", "google_mobile_ads:", "purchases_flutter:"]:
    if token not in pubspec:
        fail(f"pubspec token missing: {token}")

main_activity = (MOBILE / "android/app/src/main/kotlin/com/huzurvakti/app/MainActivity.kt").read_text(encoding="utf-8")
for token in [
    "GoogleMobileAdsPlugin.registerNativeAdFactory",
    "GoogleMobileAdsPlugin.unregisterNativeAdFactory",
    "huzur_glass_native",
    "HuzurGlassNativeAdFactory",
    "R.layout.native_ad_glass",
    "NativeAdView",
    "setNativeAd",
]:
    if token not in main_activity:
        fail(f"MainActivity NativeAdFactory token missing: {token}")

layout = (MOBILE / "android/app/src/main/res/layout/native_ad_glass.xml").read_text(encoding="utf-8")
for token in [
    "com.google.android.gms.ads.nativead.NativeAdView",
    "@+id/ad_headline",
    "@+id/ad_body",
    "@+id/ad_call_to_action",
    "@drawable/native_ad_glass_background",
]:
    if token not in layout:
        fail(f"Android native ad layout token missing: {token}")

swift = (MOBILE / "ios/Runner/HuzurGlassNativeAdFactory.swift").read_text(encoding="utf-8")
for token in [
    "FLTNativeAdFactory",
    "NativeAdView",
    "UIColor",
    "cornerRadius",
    "headlineView",
    "callToActionView",
    "nativeAd",
]:
    if token not in swift:
        fail(f"iOS NativeAdFactory token missing: {token}")

app_delegate = (MOBILE / "ios/Runner/AppDelegate.swift").read_text(encoding="utf-8")
for token in [
    "GoogleMobileAds",
    "registerNativeAdFactory",
    "huzur_glass_native",
    "HuzurGlassNativeAdFactory",
]:
    if token not in app_delegate:
        fail(f"AppDelegate factory registration token missing: {token}")

dashboard_ad = (MOBILE / "lib/widgets/dashboard_native_ad.dart").read_text(encoding="utf-8")
for token in ["factoryId: 'huzur_glass_native'", "NativeAd", "AdWidget"]:
    if token not in dashboard_ad:
        fail(f"Dashboard NativeAd token missing: {token}")

secure = (MOBILE / "lib/core/services/premium_secure_storage_service.dart").read_text(encoding="utf-8")
for token in [
    "FlutterSecureStorage",
    "encryptedSharedPreferences",
    "saveVerifiedPremium",
    "readCachedPremium",
    "premium.verified_at",
]:
    if token not in secure:
        fail(f"Premium secure storage token missing: {token}")

revenuecat = (MOBILE / "lib/core/services/revenuecat_service.dart").read_text(encoding="utf-8")
for token in [
    "PremiumSecureStorageService",
    "Purchases.purchasePackage",
    "Purchases.restorePurchases",
    "_persistPremiumState",
    "restore_receipt_verification",
]:
    if token not in revenuecat:
        fail(f"RevenueCat verification token missing: {token}")

purchase = (MOBILE / "lib/core/services/purchase_service.dart").read_text(encoding="utf-8")
for token in [
    "PremiumSecureStorageService",
    "purchase.status.name",
    "saveVerifiedPremium",
    "PurchaseStatus.restored",
]:
    if token not in purchase:
        fail(f"PurchaseService secure storage token missing: {token}")

auth = (MOBILE / "lib/core/services/auth_service.dart").read_text(encoding="utf-8")
for token in ["deleteAccount", "current.delete()", "delete_account_failed"]:
    if token not in auth:
        fail(f"Auth account deletion token missing: {token}")

settings = (MOBILE / "lib/features/settings/presentation/settings_screen.dart").read_text(encoding="utf-8")
for token in ["_deleteAccount", "AppStrings.deleteAccount", "AuthService>().deleteAccount", "deleteAccountConfirm"]:
    if token not in settings:
        fail(f"Settings account deletion token missing: {token}")

consent = (MOBILE / "lib/core/services/ad_consent_service.dart").read_text(encoding="utf-8")
for token in [
    "AdConsentService",
    "requestConsentOnFirstLaunch",
    "ConsentInformation.instance.requestConsentInfoUpdate",
    "ConsentForm.loadAndShowConsentFormIfRequired",
    "showPrivacyOptions",
]:
    if token not in consent:
        fail(f"AdConsentService UMP token missing: {token}")

main = (MOBILE / "lib/main.dart").read_text(encoding="utf-8")
for token in [
    "AdConsentService",
    "admob_ump_consent_first_launch",
    "requestConsentOnFirstLaunch",
]:
    if token not in main:
        fail(f"main.dart AdConsentService token missing: {token}")

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

print("✅ Native monetization integration audit passed.")
