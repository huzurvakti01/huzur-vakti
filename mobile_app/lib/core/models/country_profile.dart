import 'calculation_method.dart';

class CountryProfile {
  final String code;
  final String flag;
  final String nameTr;
  final String nameEn;
  final CalculationMethod method;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const CountryProfile({
    required this.code,
    required this.flag,
    required this.nameTr,
    required this.nameEn,
    required this.method,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  String label(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return nameTr;
      default:
        return nameEn;
    }
  }

  bool contains(double latitude, double longitude) {
    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLon &&
        longitude <= maxLon;
  }

  static const all = [
    CountryProfile(
      code: 'TR',
      flag: '🇹🇷',
      nameTr: 'Türkiye',
      nameEn: 'Türkiye',
      method: CalculationMethod.diyanet,
      minLat: 35,
      maxLat: 43,
      minLon: 25,
      maxLon: 45,
    ),
    CountryProfile(
      code: 'SA',
      flag: '🇸🇦',
      nameTr: 'Suudi Arabistan',
      nameEn: 'Saudi Arabia',
      method: CalculationMethod.ummAlQura,
      minLat: 15,
      maxLat: 33,
      minLon: 34,
      maxLon: 56,
    ),
    CountryProfile(
      code: 'US',
      flag: '🇺🇸',
      nameTr: 'Amerika Birleşik Devletleri',
      nameEn: 'United States',
      method: CalculationMethod.isna,
      minLat: 24,
      maxLat: 50,
      minLon: -125,
      maxLon: -66,
    ),
    CountryProfile(
      code: 'CA',
      flag: '🇨🇦',
      nameTr: 'Kanada',
      nameEn: 'Canada',
      method: CalculationMethod.isna,
      minLat: 42,
      maxLat: 72,
      minLon: -141,
      maxLon: -52,
    ),
    CountryProfile(
      code: 'GB',
      flag: '🇬🇧',
      nameTr: 'Birleşik Krallık',
      nameEn: 'United Kingdom',
      method: CalculationMethod.mwl,
      minLat: 49,
      maxLat: 61,
      minLon: -9,
      maxLon: 2,
    ),
    CountryProfile(
      code: 'FR',
      flag: '🇫🇷',
      nameTr: 'Fransa',
      nameEn: 'France',
      method: CalculationMethod.mwl,
      minLat: 41,
      maxLat: 51,
      minLon: -5,
      maxLon: 10,
    ),
    CountryProfile(
      code: 'DE',
      flag: '🇩🇪',
      nameTr: 'Almanya',
      nameEn: 'Germany',
      method: CalculationMethod.mwl,
      minLat: 47,
      maxLat: 55,
      minLon: 5,
      maxLon: 16,
    ),
    CountryProfile(
      code: 'ID',
      flag: '🇮🇩',
      nameTr: 'Endonezya',
      nameEn: 'Indonesia',
      method: CalculationMethod.mwl,
      minLat: -11,
      maxLat: 6,
      minLon: 95,
      maxLon: 141,
    ),
    CountryProfile(
      code: 'PK',
      flag: '🇵🇰',
      nameTr: 'Pakistan',
      nameEn: 'Pakistan',
      method: CalculationMethod.mwl,
      minLat: 23,
      maxLat: 37,
      minLon: 60,
      maxLon: 78,
    ),
    CountryProfile(
      code: 'IN',
      flag: '🇮🇳',
      nameTr: 'Hindistan',
      nameEn: 'India',
      method: CalculationMethod.mwl,
      minLat: 6,
      maxLat: 36,
      minLon: 68,
      maxLon: 98,
    ),
    CountryProfile(
      code: 'MY',
      flag: '🇲🇾',
      nameTr: 'Malezya',
      nameEn: 'Malaysia',
      method: CalculationMethod.mwl,
      minLat: 0,
      maxLat: 8,
      minLon: 99,
      maxLon: 120,
    ),
    CountryProfile(
      code: 'AE',
      flag: '🇦🇪',
      nameTr: 'Birleşik Arap Emirlikleri',
      nameEn: 'United Arab Emirates',
      method: CalculationMethod.ummAlQura,
      minLat: 22,
      maxLat: 27,
      minLon: 51,
      maxLon: 57,
    ),
    CountryProfile(
      code: 'QA',
      flag: '🇶🇦',
      nameTr: 'Katar',
      nameEn: 'Qatar',
      method: CalculationMethod.ummAlQura,
      minLat: 24,
      maxLat: 27,
      minLon: 50,
      maxLon: 52,
    ),
    CountryProfile(
      code: 'EG',
      flag: '🇪🇬',
      nameTr: 'Mısır',
      nameEn: 'Egypt',
      method: CalculationMethod.mwl,
      minLat: 22,
      maxLat: 32,
      minLon: 25,
      maxLon: 36,
    ),
    CountryProfile(
      code: 'MA',
      flag: '🇲🇦',
      nameTr: 'Fas',
      nameEn: 'Morocco',
      method: CalculationMethod.mwl,
      minLat: 21,
      maxLat: 36,
      minLon: -17,
      maxLon: -1,
    ),
    CountryProfile(
      code: 'NG',
      flag: '🇳🇬',
      nameTr: 'Nijerya',
      nameEn: 'Nigeria',
      method: CalculationMethod.mwl,
      minLat: 4,
      maxLat: 14,
      minLon: 2,
      maxLon: 15,
    ),
    CountryProfile(
      code: 'AU',
      flag: '🇦🇺',
      nameTr: 'Avustralya',
      nameEn: 'Australia',
      method: CalculationMethod.mwl,
      minLat: -44,
      maxLat: -10,
      minLon: 112,
      maxLon: 154,
    ),
  ];

  static CountryProfile fallback() => all.first;

  static CountryProfile byCode(String code) {
    return all.firstWhere(
      (country) => country.code == code,
      orElse: fallback,
    );
  }

  static CountryProfile byCoordinates(double latitude, double longitude) {
    return all.firstWhere(
      (country) => country.contains(latitude, longitude),
      orElse: () {
        if (latitude >= 15 && latitude <= 33 && longitude >= 34 && longitude <= 56) {
          return byCode('SA');
        }

        if (latitude >= 24 && latitude <= 72 && longitude >= -170 && longitude <= -50) {
          return byCode('US');
        }

        return fallback();
      },
    );
  }
}
