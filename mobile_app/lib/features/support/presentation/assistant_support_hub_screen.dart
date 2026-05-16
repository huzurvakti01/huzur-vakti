import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_god_mode_resolver.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class AssistantSupportHubScreen extends StatelessWidget {
  const AssistantSupportHubScreen({super.key});

  static const screenKey = 'assistant_support';

  void _open(BuildContext context, String route, String targetKey) {
    context.read<AdService>().trackNavigation(
          context: context,
          fromScreenKey: screenKey,
          toScreenKey: targetKey,
        );
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final godMode = context.watch<AppGodModeResolver>();
    final items = [
      _HubItem(
        title: AppStrings.quickAiGuide,
        subtitle: 'GPT-4o tabanlı İslami rehber',
        icon: Icons.smart_toy_rounded,
        route: '/ai',
        keyName: 'ai',
      ),
      _HubItem(
        title: AppStrings.helpdeskTitle,
        subtitle: AppStrings.helpdeskSubtitle,
        icon: Icons.support_agent_rounded,
        route: '/helpdesk',
        keyName: HelpdeskScreenKey.value,
      ),
      _HubItem(
        title: AppStrings.profileBackupTitle,
        subtitle: 'Giriş, bulut yedekleme ve hesap',
        icon: Icons.cloud_done_rounded,
        route: '/profile-backup',
        keyName: 'profile_backup',
      ),
      _HubItem(
        title: AppStrings.premiumTitle,
        subtitle: 'VIP özellikleri ve reklamsız kullanım',
        icon: Icons.workspace_premium_rounded,
        route: '/premium',
        keyName: 'premium',
      ),
    ];

    final visibleItems = items.where((item) => godMode.flags.routeEnabled(item.route)).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.assistantSupportTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const GlassCard(
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppTheme.gold),
                SizedBox(width: 12),
                Expanded(child: Text(AppStrings.assistantSupportSubtitle)),
              ],
            ),
          ),
          ...visibleItems.map(
            (item) => GlassCard(
              onTap: () => _open(context, item.route, item.keyName),
              child: ListTile(
                leading: Icon(item.icon, color: AppTheme.emerald),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ),
          const SafeBannerAd(screenKey: screenKey),
        ],
      ),
    );
  }
}

class HelpdeskScreenKey {
  static const value = 'helpdesk';
}

class _HubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String keyName;

  const _HubItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.keyName,
  });
}
