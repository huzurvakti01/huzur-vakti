# Huzur Vakti AI God Mode Admin

## Overview

This project is a separate Flutter Web + Firebase Admin panel with God Mode controls and OpenAI-backed autopilot features.

## AI Autopilot Backend

All OpenAI calls are handled in Firebase Cloud Functions. The Flutter Web panel never stores the OpenAI API key.

Required environment variables:

```bash
firebase functions:config:set admin.emails="bilal.dag403@gmail.com,admin@example.com"
# or for v2 runtime:
export ADMIN_EMAILS="bilal.dag403@gmail.com,admin@example.com"
export OPENAI_API_KEY="sk-..."
export OPENAI_MODEL="gpt-4o-mini"
```

## Cloud Functions

### Admin / God Mode

- `assertGodModeAdmin`
- `listAuthUsers`
- `updateUserGodMode`
- `hardDeleteUser`
- `resetUserPassword`
- `banUserDevice`
- `publishKillSwitchConfig`

### AI Autopilot

- `analyzeDuaText`
- `aiModerateDuaOnCreate`
- `generateDailyIslamicContent`
- `scheduledDailyIslamicContent`
- `generateDashboardAiSummary`

## AI Auto Moderation

Trigger:

```text
dua_requests/{duaId}
```

Flow:

1. New dua document is created.
2. Cloud Function sends text to OpenAI.
3. OpenAI returns JSON:
   - `toxicity_score`
   - `sentiment`
   - `categories`
   - `reason`
4. If `toxicity_score > 0.8`, the dua is deleted.
5. Every AI decision is logged to:

```text
ai_action_logs
```

## AI Content Studio

Screen:

```text
lib/screens/ai_studio_screen.dart
```

Writes generated content to:

```text
daily_content/{yyyy-mm-dd}
```

Generated fields:

- `ayah`
- `hadith`
- `dua`
- `theme`
- `generatedBy`
- `generatedAt`

## AI Dashboard Summary

Dashboard includes an AI summary card. The callable function reads aggregate Firestore signals and returns:

- summary
- risks
- opportunities
- recommended_actions

## User Matrix God Mode

Admins can:

- Edit premium / VIP state
- Edit premium expiration
- Edit dhikr count
- Edit qaza counts
- Edit streak
- Generate password reset link
- Ban device by device ID
- Hard delete Auth + Firestore user

## Emergency Controls

Kill Switch screen publishes both:

- Firestore: `admin_settings/kill_switch`
- Firebase Remote Config:
  - `force_update_enabled`
  - `min_version_code`
  - `ai_chat_enabled`
  - `zikirmatik_enabled`
  - `dua_community_enabled`
  - `premium_library_enabled`
  - `cloud_sync_enabled`
  - `godmode_config_json`
