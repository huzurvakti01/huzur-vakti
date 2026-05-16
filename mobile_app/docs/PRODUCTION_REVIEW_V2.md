# Production Review V2

Bu sürüm, önceki mega paketin erken sürüm kalan alanlarını sert üretim kontrolünden geçirerek güçlendirir.

## Düzeltilen Kritik Noktalar

### 1. Sabit veri kontrolü

- Kıble artık sabit derece değildir.
- `QiblaService`, kullanıcının gerçek konumu ve Kâbe koordinatlarıyla bearing hesaplar.
- Zekat nisabı sabit girilen değer olmaktan çıkarıldı.
- `FinanceRateService`, canlı XAU/TRY verisini çekmeye çalışır, gram altın/gümüş değerini üretir.
- İnternet yoksa fallback kur kullanır ve UI bunu açıkça gösterir.
- Namaz vakitleri zaten AlAdhan method 13 üzerinden alınır; hata durumunda UI retry gösterir.

### 2. State Management

- `AdService` artık `ChangeNotifier`.
- Premium veya Çocuk Modu değiştiğinde tüm reklam state'i global kapanır.
- Banner widget'ları premium/kids state değişiminde anında dispose edilir.
- Interstitial cache, sayaç ve yükleme state'i premium/kids modda temizlenir.

### 3. Native Kod

- Android widget receiver, XML layout, provider XML ve manifest bağlantıları eklidir.
- Android `MainActivity.kt` deep link channel içerir.
- iOS WidgetKit dosyaları eklidir.
- iOS Dynamic Island / Live Activity içerik state'i deep link desteklidir.
- App Groups ve Live Activities capability Xcode'da açılmalıdır.

### 4. Audio / Background

- `AdhanAudioService` remote URL/cache tabanlıdır.
- Gerçek ezan MP3 dosyası asset'e gömülmez.
- Sadece küçük `fallback.mp3` bulunur.
- `BackgroundAlarmScheduler`, Android exact alarm + WorkManager fallback kullanır.
- Full-screen prayer notification ile kilit ekranı/uç durumlarda kullanıcı uygulamaya yönlendirilir.
- Uygulama foreground olduğunda seçili URL/cache ezan sesi çalınır.

### 5. UI/UX

- ThemeData Apple benzeri geçişler, yumuşak rounded alanlar, InputDecoration ve NavigationBar detaylarıyla güçlendirildi.
- `GlassCard` gerçek blur/backdrop efektiyle yeniden yazıldı.
- Hassas ibadet ekranlarında reklam yoktur.
- Çocuk Modu global reklamsızdır.

## Yayın Öncesi Zorunlu Manuel Kontroller

- `flutterfire configure`
- Firebase Auth/Firestore/Remote Config ayarları
- AdMob gerçek App ID / Unit ID değerleri
- IAP ürünlerinin Google Play Console ve App Store Connect içinde açılması
- Google Maps API key
- Android exact alarm izin davranışı
- iOS App Groups + Live Activities capability
- Gerçek cihazda background alarm testi
- Store policy ve dini içerik açıklamaları
