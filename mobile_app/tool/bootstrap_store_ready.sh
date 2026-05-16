#!/usr/bin/env bash
set -euo pipefail

echo "== Huzur Vakti Store-Ready Bootstrap =="

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK bulunamadı. Önce Flutter stable kurun."
  exit 1
fi

if [ ! -f ".env" ]; then
  cp .env.example .env
  echo ".env oluşturuldu. Gerçek API/AdMob değerlerini girin."
fi

echo "Flutter platform dosyaları doğrulanıyor..."
flutter pub get

# Eksik platform boilerplate dosyalarını Flutter stable şablonuyla tamamlar.
# Mevcut lib/core/features kodlarını silmez.
flutter create --platforms=android,ios --org com.huzurvakti .

echo "Firebase seçeneklerini üretmek için:"
echo "  flutterfire configure"
echo ""
echo "Android release için:"
echo "  cp android/key.properties.template android/key.properties"
echo "  keytool ile JKS oluşturup key.properties değerlerini doldurun."
echo ""
echo "Kontrol:"
python3 tool/release_audit.py

echo "Hazır. Sonraki komutlar:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter build appbundle --release"
echo "  flutter build ipa --release"
