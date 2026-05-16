import 'finance_rate_service.dart';

class ZakatResult {
  final double totalAssets;
  final double nisabValue;
  final double zakatDue;
  final bool eligible;
  final bool rateFallback;

  const ZakatResult({
    required this.totalAssets,
    required this.nisabValue,
    required this.zakatDue,
    required this.eligible,
    required this.rateFallback,
  });
}

class ZakatService {
  ZakatResult calculate({
    required double cash,
    required double goldGram,
    required double silverGram,
    required double tradeGoods,
    required double debts,
    required FinanceRates rates,
    bool useGoldNisab = true,
  }) {
    final goldValue = goldGram * rates.gramGoldTry;
    final silverValue = silverGram * rates.gramSilverTry;
    final total = cash + goldValue + silverValue + tradeGoods - debts;
    final nisab = useGoldNisab ? rates.nisabGoldTry : rates.nisabSilverTry;
    final eligible = total >= nisab;

    return ZakatResult(
      totalAssets: total,
      nisabValue: nisab,
      eligible: eligible,
      rateFallback: rates.fallback,
      zakatDue: eligible ? total * .025 : 0,
    );
  }
}
