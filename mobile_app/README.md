# Huzur Vakti Mobile Mega Project

Feature-first, Provider + go_router mimarili premium Flutter mobil uygulama.

## Öne Çıkanlar

- `lib/core`, `lib/features`, `lib/shared` mimarisi
- Firebase, AdMob, IAP, Local Notifications güvenli başlatma akışı
- AlAdhan API method 13 namaz vakitleri
- flutter_compass Kıble
- Dinamik URL/cache tabanlı ezan sesi motoru
- Premium satın alma altyapısı
- Akıllı reklam sayacı
- Reklamsız hassas ekranlar
- Firebase Firestore Dua Kardeşliği
- Oyunlaştırılmış kaza takibi
- Akıllı Seferi Modu
- Uyku/Teheccüd Asistanı
- Zekat Hesaplayıcı
- COPPA uyumlu tamamen reklamsız Çocuk Modu
- Android Kotlin + iOS Swift native widget iskeletleri

## Kurulum

```bash
flutter pub get
flutterfire configure
flutter run
```

`.env.example` dosyasını `.env` olarak kopyalayın ve gerçek anahtarları girin.

## Güvenlik

OpenAI API key mobil projeye konmaz. AI ekranı sadece güvenli backend proxy endpoint'ine bağlanır.

## Store-Ready Son Hazırlık

Bu paket kaynak kod + platform yapılandırmalarıyla mağaza build'ine hazırlanmıştır. Gerçek mağaza build'i için geliştirici makinesinde şu komutları çalıştırın:

```bash
bash tool/bootstrap_store_ready.sh
python3 tool/final_preflight.py
flutter analyze
flutter test
flutter build appbundle --release
flutter build ipa --release
```

Gerçek Firebase, AdMob, Google Maps ve IAP değerleri kişisel hesaplarınıza bağlı olduğu için ZIP içine gerçek gizli anahtar konmaz.
