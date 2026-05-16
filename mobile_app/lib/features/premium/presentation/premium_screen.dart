import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/error_presenter.dart';
import '../../../core/logging/app_logger.dart';

import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/constants/app_strings.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  static const revenueCatEntitlement = 'premium';
  static const monthlyProductId = 'premium_monthly';
  static const yearlyProductId = 'premium_yearly';
  static const lifetimeProductId = 'premium_lifetime';

  static const screenKey = 'premium';

  @override
  Widget build(BuildContext context) {
    final purchase = context.watch<PurchaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.premiumTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 74, color: AppTheme.gold),
                const SizedBox(height: 16),
                Text(
                  AppStrings.premiumHeading,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.premiumDescription,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'RevenueCat: premium_monthly • premium_yearly • premium_lifetime',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (purchase.loading)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
          else if (purchase.products.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  Text(purchase.isPremium ? AppStrings.premiumActive : AppStrings.premiumProductsUnavailable),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: purchase.reloadProducts,
                          child: const Text(AppStrings.reloadStoreProducts),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              await purchase.restorePurchases();
                            } catch (error, stackTrace) {
                              AppLogger.error(
                                AppStrings.logPremiumPurchaseFailed,
                                error: error,
                                stackTrace: stackTrace,
                              );
                              if (context.mounted) {
                                ErrorPresenter.showSnackBar(context, error);
                              }
                            }
                          },
                          child: const Text(AppStrings.restorePurchases),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            ...purchase.products.map(
              (p) => GlassCard(
                child: ListTile(
                  title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(p.description),
                  trailing: Text(p.price),
                  onTap: () async {
                    try {
                      await purchase.buy(p);
                    } catch (error, stackTrace) {
                      AppLogger.error(
                        AppStrings.logPremiumPurchaseFailed,
                        error: error,
                        stackTrace: stackTrace,
                        context: {'productId': p.id},
                      );
                      if (context.mounted) {
                        ErrorPresenter.showSnackBar(context, error);
                      }
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
