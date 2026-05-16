import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class PremiumAudioLibraryScreen extends StatelessWidget {
  const PremiumAudioLibraryScreen({super.key});

  static const screenKey = 'premium_audio_library';

  static const _items = [
    _PremiumAudioItem(
      title: AppStrings.premiumLibraryMeditation1,
      subtitle: AppStrings.premiumLibraryMeditation1Subtitle,
      icon: Icons.wb_sunny_rounded,
      minutes: 8,
    ),
    _PremiumAudioItem(
      title: AppStrings.premiumLibraryMeditation2,
      subtitle: AppStrings.premiumLibraryMeditation2Subtitle,
      icon: Icons.nights_stay_rounded,
      minutes: 10,
    ),
    _PremiumAudioItem(
      title: AppStrings.premiumLibraryMeditation3,
      subtitle: AppStrings.premiumLibraryMeditation3Subtitle,
      icon: Icons.favorite_rounded,
      minutes: 12,
    ),
    _PremiumAudioItem(
      title: AppStrings.premiumLibraryMeditation4,
      subtitle: AppStrings.premiumLibraryMeditation4Subtitle,
      icon: Icons.dark_mode_rounded,
      minutes: 7,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseService>().isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.premiumLibraryTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: Row(
              children: [
                Icon(
                  isPremium ? Icons.headphones_rounded : Icons.lock_rounded,
                  color: isPremium ? AppTheme.gold : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isPremium ? AppStrings.premiumLibrarySubtitle : AppStrings.premiumLibraryLocked,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (!isPremium)
                  TextButton(
                    onPressed: () => context.push('/premium'),
                    child: const Text(AppStrings.upgradeToPremium),
                  ),
              ],
            ),
          ),
          ..._items.map((item) {
            return GlassCard(
              onTap: isPremium
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          content: Text(AppStrings.format(AppStrings.premiumLibraryPreparing, {'title': item.title})),
                        ),
                      );
                    }
                  : () => context.push('/premium'),
              child: ListTile(
                leading: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withOpacity(.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(item.icon, color: AppTheme.emerald),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${item.subtitle} • ${AppStrings.format(AppStrings.minutesShort, {'count': item.minutes})}'),
                trailing: FilledButton.tonalIcon(
                  onPressed: isPremium ? () {} : () => context.push('/premium'),
                  icon: Icon(isPremium ? Icons.play_arrow_rounded : Icons.lock_rounded),
                  label: Text(isPremium ? AppStrings.premiumLibraryPlay : AppStrings.upgradeToPremium),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PremiumAudioItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final int minutes;

  const _PremiumAudioItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.minutes,
  });
}
