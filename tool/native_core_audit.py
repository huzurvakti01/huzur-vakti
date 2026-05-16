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
    MOBILE / "lib/core/services/background_alarm_manager.dart",
    MOBILE / "lib/core/services/background_alarm_scheduler.dart",
    MOBILE / "lib/core/services/prayer_dnd_service.dart",
    MOBILE / "lib/shared/widgets/dnd_permission_card.dart",
    MOBILE / "lib/features/tools/presentation/prayer_dnd_screen.dart",
    MOBILE / "android/app/src/main/AndroidManifest.xml",
    MOBILE / "ios/Runner/Info.plist",
    ROOT / "docs/NATIVE_CORE_STABILITY.md",
]

for path in required:
    if not path.exists():
        fail(f"Missing required file: {path.relative_to(ROOT)}")

pubspec = (MOBILE / "pubspec.yaml").read_text(encoding="utf-8")
for token in [
    "android_intent_plus:",
    "flutter_local_notifications:",
    "android_alarm_manager_plus:",
    "workmanager:",
]:
    if token not in pubspec:
        fail(f"pubspec dependency missing: {token}")

manager = (MOBILE / "lib/core/services/background_alarm_manager.dart").read_text(encoding="utf-8")
for token in [
    "AndroidIntent",
    "REQUEST_SCHEDULE_EXACT_ALARM",
    "IGNORE_BATTERY_OPTIMIZATION_SETTINGS",
    "canScheduleExactNotifications",
    "requestExactAlarmsPermission",
    "zonedSchedule",
    "AndroidScheduleMode.exactAllowWhileIdle",
    "AndroidAlarmManager.oneShotAt",
    "allowWhileIdle: true",
    "rescheduleOnReboot: true",
    "Workmanager().registerOneOffTask",
    "fullScreenIntent: true",
    "AudioAttributesUsage.alarm",
]:
    if token not in manager:
        fail(f"background_alarm_manager token missing: {token}")

scheduler = (MOBILE / "lib/core/services/background_alarm_scheduler.dart").read_text(encoding="utf-8")
for token in ["BackgroundAlarmManager", "requestExactAlarmPermission", "openBatteryOptimizationSettings", "canScheduleExactAlarms"]:
    if token not in scheduler:
        fail(f"background_alarm_scheduler facade token missing: {token}")

dnd_service = (MOBILE / "lib/core/services/prayer_dnd_service.dart").read_text(encoding="utf-8")
for token in ["hasPolicyAccess", "openPolicySettings", "ensurePolicyAccess", "gotoPolicySettings", "setInterruptionFilter"]:
    if token not in dnd_service:
        fail(f"DND service token missing: {token}")

dnd_widget = (MOBILE / "lib/shared/widgets/dnd_permission_card.dart").read_text(encoding="utf-8")
for token in ["DndPermissionCard", "hasPolicyAccess", "openPolicySettings", "dndPermissionMissing", "dndOpenPolicySettings", "GlassCard"]:
    if token not in dnd_widget:
        fail(f"DND permission widget token missing: {token}")

dnd_screen = (MOBILE / "lib/features/tools/presentation/prayer_dnd_screen.dart").read_text(encoding="utf-8")
if "DndPermissionCard" not in dnd_screen:
    fail("Prayer DND screen must include DndPermissionCard")

manifest = (MOBILE / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
for token in [
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.USE_EXACT_ALARM",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.WAKE_LOCK",
    "android.permission.USE_FULL_SCREEN_INTENT",
    "android.permission.ACCESS_NOTIFICATION_POLICY",
    "android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS",
    "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver",
    "com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver",
    "android.intent.action.BOOT_COMPLETED",
    "android.intent.action.MY_PACKAGE_REPLACED",
]:
    if token not in manifest:
        fail(f"AndroidManifest token missing: {token}")

plist = (MOBILE / "ios/Runner/Info.plist").read_text(encoding="utf-8")
for token in [
    "<key>UIBackgroundModes</key>",
    "<string>audio</string>",
    "<string>location</string>",
    "<string>fetch</string>",
    "<string>remote-notification</string>",
    "NSLocationAlwaysAndWhenInUseUsageDescription",
]:
    if token not in plist:
        fail(f"Info.plist token missing: {token}")

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

print("✅ Native core stability audit passed.")
