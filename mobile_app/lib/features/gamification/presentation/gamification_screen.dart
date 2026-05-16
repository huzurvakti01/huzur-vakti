import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  static const screenKey = 'gamification';

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GamificationService>();
    final auth = context.watch<AuthService>();
    final progress = service.progress;
    final qaza = progress.qazaCounts;
    final cloudAvailable = service.cloudSyncAvailable;

    final syncText = cloudAvailable
        ? AppStrings.cloudSyncFreeActive
        : (auth.isGuest ? AppStrings.cloudSyncGuestLocalOnly : AppStrings.cloudSyncNeedsLogin);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.gamificationTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: Row(
              children: [
                Icon(
                  cloudAvailable ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: cloudAvailable ? AppTheme.emerald : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    syncText,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (service.cloudSyncing)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else if (cloudAvailable)
                  TextButton(
                    onPressed: service.backupNow,
                    child: const Text(AppStrings.syncNow),
                  ),
              ],
            ),
          ),
          if (cloudAvailable && service.lastCloudSyncAt != null)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                AppStrings.format(
                  AppStrings.cloudSyncLast,
                  {'time': service.lastCloudSyncAt!.toLocal().toString().split('.').first},
                ),
              ),
            ),
          if (auth.isSignedIn && auth.user?.email != null)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                AppStrings.format(AppStrings.signedInAs, {'email': auth.user!.email!}),
              ),
            ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.dailyGoal,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.format(
                    AppStrings.streakDays,
                    {'count': progress.streakDays},
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: progress.completion,
                  minHeight: 14,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.format(
                    AppStrings.dailyGoalLiveProgress,
                    {
                      'quran': progress.quranPagesToday,
                      'quranTarget': progress.dailyQuranPageTarget,
                      'dhikr': progress.dhikrToday,
                      'dhikrTarget': progress.dailyDhikrTarget,
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: service.addQuranPage,
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text(AppStrings.addQuranPage),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => service.addDhikr(amount: 10),
                        icon: const Icon(Icons.favorite_rounded),
                        label: const Text(AppStrings.addTenDhikr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GlassCard(
            child: SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final keys = qaza.keys.toList();
                          if (value.toInt() < 0 || value.toInt() >= keys.length) return const SizedBox();
                          return Text(keys[value.toInt()].substring(0, 2));
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: qaza.values.toList().asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          width: 24,
                          borderRadius: BorderRadius.circular(8),
                          color: entry.value == 0 ? AppTheme.emerald : AppTheme.gold,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          ...qaza.entries.map((entry) {
            return GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => service.setQazaCount(entry.key, entry.value - 1),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text(
                    AppStrings.formatIndex(entry.value),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => service.setQazaCount(entry.key, entry.value + 1),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
            );
          }),
          const SafeBannerAd(screenKey: GamificationScreen.screenKey),
        ],
      ),
    );
  }
}
