# Huzur Vakti Security Hardening

## OpenAI Security Proxy

Mobile code no longer talks to OpenAI directly.

Mobile client:

```text
mobile_app/lib/core/services/ai_client_service.dart
```

Server proxy:

```text
admin_panel/functions/index.js
```

Proxy endpoint:

```text
openAiChatProxy
```

Security controls:

- Firebase ID token required
- User-specific rate limiting: max 5 requests per minute
- Audit logs written to `ai_audit_logs`
- Server-side `OPENAI_API_KEY`
- No OpenAI API key in mobile app

## Firestore Security Rules

Root rules file:

```text
firestore.rules
```

Protected collections:

- `users`
- `tickets`
- `support_tickets`
- `dualar`

Admin access:

```text
request.auth.token.isAdmin == true
```

## Crash and Analytics

Core services:

```text
mobile_app/lib/core/services/crash_reporting_service.dart
mobile_app/lib/core/services/analytics_service.dart
```

Bootstrap:

```text
mobile_app/lib/main.dart
```

Firebase Crashlytics captures Flutter and platform dispatcher fatal errors. Firebase Analytics logs app open, screen and AI usage events.
