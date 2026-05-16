class CalculationMethod {
  final int id;
  final String title;
  final String subtitle;

  const CalculationMethod({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  static const diyanet = CalculationMethod(
    id: 13,
    title: 'Diyanet',
    subtitle: 'Türkiye ve Diyanet yöntemi',
  );

  static const mwl = CalculationMethod(
    id: 3,
    title: 'MWL',
    subtitle: 'Muslim World League',
  );

  static const isna = CalculationMethod(
    id: 2,
    title: 'ISNA',
    subtitle: 'North America',
  );

  static const ummAlQura = CalculationMethod(
    id: 4,
    title: 'Umm Al-Qura',
    subtitle: 'Saudi Arabia',
  );

  static const all = [diyanet, mwl, isna, ummAlQura];

  static CalculationMethod byId(int id) {
    return all.firstWhere(
      (method) => method.id == id,
      orElse: () => mwl,
    );
  }
}
