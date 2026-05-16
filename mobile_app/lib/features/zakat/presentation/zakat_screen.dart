import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/finance_rate_service.dart';
import '../../../core/services/zakat_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';
import '../../../core/constants/app_strings.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  static const screenKey = 'zakat';

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final cash = TextEditingController();
  final goldGram = TextEditingController();
  final silverGram = TextEditingController();
  final trade = TextEditingController();
  final debts = TextEditingController();

  FinanceRates? rates;
  ZakatResult? result;
  bool loadingRates = true;
  bool useGoldNisab = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() => loadingRates = true);
    final fetched = await context.read<FinanceRateService>().fetchRates();
    if (!mounted) return;
    setState(() {
      rates = fetched;
      loadingRates = false;
    });
  }

  double _v(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  void _calc() {
    final r = rates;
    if (r == null) return;

    result = context.read<ZakatService>().calculate(
          cash: _v(cash),
          goldGram: _v(goldGram),
          silverGram: _v(silverGram),
          tradeGoods: _v(trade),
          debts: _v(debts),
          rates: r,
          useGoldNisab: useGoldNisab,
        );
    setState(() {});
  }

  @override
  void dispose() {
    cash.dispose();
    goldGram.dispose();
    silverGram.dispose();
    trade.dispose();
    debts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = rates;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.zakatTitle),
        actions: [IconButton(onPressed: _loadRates, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: loadingRates
                ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.liveRates, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Text(AppStrings.format(AppStrings.gramGold, {'value': r!.gramGoldTry.toStringAsFixed(2)})),
                      Text(AppStrings.format(AppStrings.gramSilver, {'value': r.gramSilverTry.toStringAsFixed(2)})),
                      Text(AppStrings.format(AppStrings.nisab, {'value': (useGoldNisab ? r.nisabGoldTry : r.nisabSilverTry).toStringAsFixed(2)})),
                      if (r.fallback)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            AppStrings.offlineRatesWarning,
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w800),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: useGoldNisab,
                        onChanged: (v) => setState(() => useGoldNisab = v),
                        title: const Text(AppStrings.useGoldNisab),
                        subtitle: const Text(AppStrings.useGoldNisabSubtitle),
                      ),
                    ],
                  ),
          ),
          GlassCard(
            child: Column(
              children: [
                _field(AppStrings.cashBank, cash),
                _field(AppStrings.goldGram, goldGram),
                _field(AppStrings.silverGram, silverGram),
                _field(AppStrings.tradeGoods, trade),
                _field(AppStrings.debts, debts),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: loadingRates ? null : _calc, child: const Text(AppStrings.calculate))),
              ],
            ),
          ),
          if (result != null)
            GlassCard(
              child: Column(
                children: [
                  Text(AppStrings.format(AppStrings.totalAssets, {'value': result!.totalAssets.toStringAsFixed(2)})),
                  const SizedBox(height: 10),
                  Text(
                    result!.eligible ? AppStrings.format(AppStrings.zakatDue, {'value': result!.zakatDue.toStringAsFixed(2)}) : AppStrings.belowNisab,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(AppStrings.format(AppStrings.usedNisab, {'value': result!.nisabValue.toStringAsFixed(2)})),
                  const SizedBox(height: 8),
                  const Text(AppStrings.zakatDisclaimer),
                ],
              ),
            ),
          const SafeBannerAd(screenKey: ZakatScreen.screenKey),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
