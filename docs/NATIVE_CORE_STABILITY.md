# Native Core Stability

## Exact Alarm

Main service:

```text
mobile_app/lib/core/services/background_alarm_manager.dart
```

Uses:

- `flutter_local_notifications.zonedSchedule`
- `AndroidScheduleMode.exactAllowWhileIdle`
- `android_intent_plus` for exact alarm settings
- `android_alarm_manager_plus` fallback
- `workmanager` fallback
- boot-reschedule receiver declarations

## DND Permission

Service and widget:

```text
mobile_app/lib/core/services/prayer_dnd_service.dart
mobile_app/lib/shared/widgets/dnd_permission_card.dart
```

Flow:

- Checks Android Notification Policy Access
- Opens system DND policy settings if not granted
- Displays a glassmorphism permission warning card

## Android Manifest

Critical permissions:

- `SCHEDULE_EXACT_ALARM`
- `USE_EXACT_ALARM`
- `RECEIVE_BOOT_COMPLETED`
- `WAKE_LOCK`
- `USE_FULL_SCREEN_INTENT`
- `ACCESS_NOTIFICATION_POLICY`
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- `POST_NOTIFICATIONS`

## iOS Info.plist

Background modes:

- `audio`
- `location`
- `fetch`
- `remote-notification`
