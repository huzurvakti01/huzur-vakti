# Store Release Checklist

## 1. Firebase

- `flutterfire configure` çalıştırıldı.
- `lib/firebase_options.dart` gerçek proje bilgileriyle değiştirildi.
- Firestore rules deploy edildi:

```bash
firebase deploy --only firestore:rules
```

## 2. Android

- Gerçek package/applicationId: `com.huzurvakti.app`
- Keystore oluşturuldu.
- `android/key.properties` eklendi.
- AdMob App ID gerçek değerle değiştirildi.
- Google Maps Android API key gerçek değerle değiştirildi.
- Android 13+ bildirim izni test edildi.
- Exact alarm davranışı gerçek cihazda test edildi.
- Widget receiver ana ekranda test edildi.

## 3. iOS

- Bundle ID: `com.huzurvakti.app`
- App Groups capability açıldı: `group.com.huzurvakti.app`
- Live Activities capability açıldı.
- Push Notifications capability açıldı.
- Google Maps iOS key gerçek değerle değiştirildi.
- Widget extension ve Live Activity target Xcode projesine bağlandı.
- Gerçek cihazda Dynamic Island / Live Activity test edildi.

## 4. Premium / IAP

- `premium_monthly`
- `premium_yearly`
- `premium_lifetime`

ürünleri Google Play Console ve App Store Connect içinde oluşturuldu.

## 5. Reklam Politikası

Şu ekranlarda tam ekran reklam kesinlikle yoktur:

- Ana namaz ekranı
- Kur’an
- Kıble
- AI
- Çocuk Modu
- Ezan alarmı
- Teheccüd ekranı

Çocuk Modu açıkken:

- Banner yok
- Native yok
- Interstitial yok
- Reklam yükleme yok
- Sayaç yok

## 6. AI Güvenliği

OpenAI API key mobil uygulamaya konmaz.
AI ekranı yalnızca backend proxy endpoint kullanır.

## 7. Son Komutlar

```bash
python3 tool/release_audit.py
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
flutter build ipa --release
```
