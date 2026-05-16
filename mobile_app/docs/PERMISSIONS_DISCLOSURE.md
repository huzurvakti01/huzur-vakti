# Permissions Disclosure

## iOS

### Location

Used for:

- Prayer times based on current location
- Qibla direction
- Traveler mode distance calculation
- Nearby mosques

Configured keys:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`

### Notifications

Used for:

- Prayer reminders
- Adhan alarm
- Tahajjud reminders
- Optional fasting reminders

Configured keys:

- `NSUserNotificationUsageDescription`
- `UIBackgroundModes`

### App Tracking Transparency

Configured key:

- `NSUserTrackingUsageDescription`

The prompt explains that the advertising identifier is used only with user permission. Kids Mode, Home Prayer, Quran, Qibla, Adhan Alarm and AI screens remain ad-free.

### Motion

Used for Qibla compass stability.

Configured key:

- `NSMotionUsageDescription`

## Android

### Location

Used for prayer times, Qibla, Traveler Mode and nearby mosques.

Permissions:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`

### Notifications / Alarm

Used for prayer reminders, adhan alarm, full-screen alarm notification and rescheduling after reboot.

Permissions:

- `POST_NOTIFICATIONS`
- `SCHEDULE_EXACT_ALARM`
- `USE_EXACT_ALARM`
- `USE_FULL_SCREEN_INTENT`
- `RECEIVE_BOOT_COMPLETED`
- `WAKE_LOCK`
- `VIBRATE`

### Foreground Services

Used for audio playback and time-sensitive religious reminders.

Permissions:

- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
- `FOREGROUND_SERVICE_LOCATION`
- `FOREGROUND_SERVICE_DATA_SYNC`

### Ads and Maps

- AdMob app ID is configured through manifest metadata.
- Google Maps API key is configured through manifest metadata.
- Kids Mode, Quran, Qibla, Home Prayer, AI and Adhan screens are ad-free by app policy.
