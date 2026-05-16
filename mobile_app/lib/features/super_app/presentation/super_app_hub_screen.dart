import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_god_mode_resolver.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/super_app_module.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class SuperAppHubScreen extends StatelessWidget {
  const SuperAppHubScreen({super.key});

  static const screenKey = 'super_app_hub';

  static const _ibadah = [
    SuperAppModule(
      title: AppStrings.quickQaza,
      subtitle: 'Kaza, zikir ve günlük seri takibi',
      icon: Icons.emoji_events_rounded,
      route: '/gamification',
      screenKey: 'gamification',
    ),
    SuperAppModule(
      title: AppStrings.womenCalendarTitle,
      subtitle: AppStrings.womenCalendarSubtitle,
      icon: Icons.calendar_month_rounded,
      route: '/women-calendar',
      screenKey: 'women_calendar',
    ),
    SuperAppModule(
      title: AppStrings.prayerDndTitle,
      subtitle: AppStrings.prayerDndSubtitle,
      icon: Icons.do_not_disturb_on_rounded,
      route: '/prayer-dnd',
      screenKey: 'prayer_dnd',
    ),
    SuperAppModule(
      title: AppStrings.quickTahajjud,
      subtitle: 'Uyku ve teheccüd asistanı',
      icon: Icons.dark_mode_rounded,
      route: '/sleep',
      screenKey: 'tahajjud_sleep',
    ),
  ];

  static const _quran = [
    SuperAppModule(
      title: AppStrings.quranTitle,
      subtitle: 'Sureler ve reklamsız okuma',
      icon: Icons.menu_book_rounded,
      route: '/quran',
      screenKey: 'quran',
    ),
    SuperAppModule(
      title: AppStrings.mediaCenterTitle,
      subtitle: AppStrings.mediaCenterSubtitle,
      icon: Icons.live_tv_rounded,
      route: '/media-center',
      screenKey: 'media_center',
    ),
    SuperAppModule(
      title: AppStrings.ayahFinderTitle,
      subtitle: AppStrings.ayahFinderSubtitle,
      icon: Icons.graphic_eq_rounded,
      route: '/ayah-finder',
      screenKey: 'ayah_finder',
    ),
    SuperAppModule(
      title: AppStrings.khutbahTitle,
      subtitle: AppStrings.khutbahSubtitle,
      icon: Icons.article_rounded,
      route: '/khutbah',
      screenKey: 'khutbah',
    ),
  ];

  static const _social = [
    SuperAppModule(
      title: AppStrings.communityTitle,
      subtitle: 'Dua paylaş, Amin de',
      icon: Icons.favorite_rounded,
      route: '/community',
      screenKey: 'dua_brotherhood',
    ),
    SuperAppModule(
      title: AppStrings.greetingCardTitle,
      subtitle: AppStrings.greetingCardSubtitle,
      icon: Icons.collections_rounded,
      route: '/greeting-card',
      screenKey: 'greeting_card',
    ),
    SuperAppModule(
      title: AppStrings.premiumLibraryTitle,
      subtitle: AppStrings.premiumLibrarySubtitle,
      icon: Icons.headphones_rounded,
      route: '/premium-library',
      screenKey: 'premium_audio_library',
    ),
  ];

  static const _tools = [
    SuperAppModule(
      title: AppStrings.qiblaTitle,
      subtitle: 'Kıble pusulası',
      icon: Icons.explore_rounded,
      route: '/qibla',
      screenKey: 'qibla',
    ),
    SuperAppModule(
      title: AppStrings.quickAiGuide,
      subtitle: 'AI dini rehber',
      icon: Icons.smart_toy_rounded,
      route: '/ai',
      screenKey: 'ai',
    ),
    SuperAppModule(
      title: AppStrings.quickZakat,
      subtitle: 'Zekat hesaplayıcı',
      icon: Icons.calculate_rounded,
      route: '/zakat',
      screenKey: 'zakat',
    ),
    SuperAppModule(
      title: AppStrings.wallpaperTitle,
      subtitle: AppStrings.wallpaperSubtitle,
      icon: Icons.wallpaper_rounded,
      route: '/wallpapers',
      screenKey: 'wallpaper_gallery',
    ),
    SuperAppModule(
      title: AppStrings.settingsTitle,
      subtitle: 'Profil, yedekleme ve premium',
      icon: Icons.tune_rounded,
      route: '/settings',
      screenKey: 'settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStrings.navIbadah),
              Tab(text: AppStrings.navQuranHub),
              Tab(text: AppStrings.navSocial),
              Tab(text: AppStrings.navTools),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ModuleGrid(title: AppStrings.superAppIbadahTitle, modules: _ibadah),
            _ModuleGrid(title: AppStrings.superAppQuranTitle, modules: _quran),
            _ModuleGrid(title: AppStrings.superAppSocialTitle, modules: _social),
            _ModuleGrid(title: AppStrings.superAppToolsTitle, modules: _tools),
          ],
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  final String title;
  final List<SuperAppModule> modules;

  const _ModuleGrid({
    required this.title,
    required this.modules,
  });

  @override
  Widget build(BuildContext context) {
    final godMode = context.watch<AppGodModeResolver>();
    final visibleModules = modules.where((module) => godMode.flags.routeEnabled(module.route)).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.dashboard_customize_rounded, color: AppTheme.emerald),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.superAppSubtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: visibleModules.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.06,
          ),
          itemBuilder: (context, index) {
            final module = visibleModules[index];

            return GlassCard(
              margin: EdgeInsets.zero,
              onTap: () {
                context.read<AdService>().trackNavigation(
                      context: context,
                      fromScreenKey: SuperAppHubScreen.screenKey,
                      toScreenKey: module.screenKey,
                    );
                context.push(module.route);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(module.icon, size: 36, color: AppTheme.gold),
                  const Spacer(),
                  Text(module.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(module.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        ),
        const SafeBannerAd(screenKey: SuperAppHubScreen.screenKey),
      ],
    );
  }
}
