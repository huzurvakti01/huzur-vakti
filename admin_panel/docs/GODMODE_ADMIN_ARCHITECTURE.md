# Huzur Vakti God Mode Admin

## Purpose

Dark glassmorphism Flutter Web command center for advanced app control.

## Screens

- Dashboard
- User Matrix
- Absolute Moderation
- Kill Switch & Force Update
- Content Studio

## Firebase

### Authentication

Admin login uses Email/Password Firebase Auth.

### Firestore Collections

- `users`
- `users/{uid}/cloud_sync/ibadah_progress`
- `dua_requests`
- `admin_settings/kill_switch`
- `cms_content`
- `admin_audit_logs`

### Cloud Functions

- `assertGodModeAdmin`
- `listAuthUsers`
- `updateUserGodMode`
- `hardDeleteUser`
- `publishKillSwitchConfig`

## User Matrix

Admins can:

- View Firestore users
- Edit Premium / VIP state
- Edit dhikr count
- Edit qaza counts
- Edit streak days
- Hard delete Auth + Firestore user data

## Absolute Moderation

Admins can:

- List every dua, not only reported ones
- See author uid
- Edit dua text
- Delete dua

## Kill Switch

Controls:

- Force update
- Minimum version code
- AI Chat
- Zikirmatik
- Dua Community
- Premium Library
- Cloud Sync

Publishes both Firestore and Firebase Remote Config.

## Content Studio

Admins can manage:

- Daily ayah
- Daily hadith
- About text
- Static app texts
