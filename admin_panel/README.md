# Huzur Vakti God Mode Admin

Ayrı Flutter Web projesidir. Firebase Authentication, Firestore ve Cloud Functions ile çalışır.

## Modüller

- Dashboard
- User Matrix
- Absolute Moderation
- Kill Switch & Force Update
- Content Studio
- Audit Logs

## Kurulum

```bash
flutter pub get
flutter run -d chrome
```

Firebase web config değerlerini `lib/firebase_options.dart` içine kendi projenizden gelen değerlerle değiştirin.

## Cloud Functions

`functions/index.js` içindeki fonksiyonlar Firebase Admin SDK ile çalışır. Deploy:

```bash
cd functions
npm install
firebase deploy --only functions
```

## Güvenlik

Admin panele email/password ile girilir. Cloud Functions tarafında admin email whitelist uygulanır.

Environment:

```bash
firebase functions:config:set admin.emails="admin@domain.com,bilal.dag403@gmail.com"
```
