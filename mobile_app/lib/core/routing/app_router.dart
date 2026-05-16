import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/ai/presentation/ai_chat_screen.dart';
import '../../features/alarm/presentation/adhan_alarm_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/community/presentation/dua_brotherhood_screen.dart';
import '../../features/gamification/presentation/gamification_screen.dart';
import '../../features/gallery/presentation/wallpaper_gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/kids/presentation/kids_mode_screen.dart';
import '../../features/media/presentation/media_center_screen.dart';
import '../../features/onboarding/presentation/language_country_setup_screen.dart';
import '../../features/onboarding/presentation/smart_setup_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/premium/presentation/app_icon_screen.dart';
import '../../features/premium/presentation/premium_audio_library_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/premium/presentation/secure_notes_screen.dart';
import '../../features/profile/presentation/profile_backup_screen.dart';
import '../../features/qibla/presentation/qibla_screen.dart';
import '../../features/quran/presentation/quran_screen.dart';
import '../../features/quran_tools/presentation/ayah_finder_screen.dart';
import '../../features/quran_tools/presentation/khutbah_moon_screen.dart';
import '../../features/support/presentation/assistant_support_hub_screen.dart';
import '../../features/support/presentation/helpdesk_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/sleep/presentation/tahajjud_sleep_screen.dart';
import '../../features/super_app/presentation/super_app_hub_screen.dart';
import '../../features/tools/presentation/greeting_card_screen.dart';
import '../../features/tools/presentation/prayer_dnd_screen.dart';
import '../../features/traveler/presentation/traveler_mode_screen.dart';
import '../../features/women/presentation/women_calendar_screen.dart';
import '../../features/zakat/presentation/zakat_screen.dart';
import '../config/app_god_mode_resolver.dart';
import '../constants/app_strings.dart';
import '../services/auth_service.dart';
import '../services/global_settings_service.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/smart-setup',
    redirect: (context, state) {
      final auth = context.read<AuthService>();
      final location = state.matchedLocation;
      final onAuth = location == '/auth';
      final onOnboarding = location == '/onboarding';
      final onLanguageSetup = location == '/language-country-setup';
      final onSmartSetup = location == '/smart-setup';
      final setupDone = context.read<GlobalSettingsService>().languageCountrySetupCompleted;
      final godMode = context.read<AppGodModeResolver>();
      final editingLanguageSetup = state.uri.queryParameters['edit'] == '1';

      if (!setupDone && !onLanguageSetup && !onSmartSetup) {
        return '/smart-setup';
      }

      if (setupDone && (onLanguageSetup || onSmartSetup) && !editingLanguageSetup) {
        return auth.user == null ? '/auth' : '/';
      }

      if (auth.user == null && !onAuth && !onOnboarding && !onLanguageSetup && !onSmartSetup) {
        return '/auth';
      }

      if (auth.user != null && (onAuth || onOnboarding)) {
        return '/';
      }

      if (!godMode.flags.routeEnabled(location)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/smart-setup', builder: (_, __) => const SmartSetupScreen()),
      GoRoute(path: '/language-country-setup', builder: (_, __) => const LanguageCountrySetupScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/quran', builder: (_, __) => const QuranScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tools', builder: (_, __) => const SuperAppHubScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/assistant-support', builder: (_, __) => const AssistantSupportHubScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/ai', builder: (_, __) => const AiChatScreen()),
      GoRoute(path: '/kids', builder: (_, __) => const KidsModeScreen()),
      GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
      GoRoute(path: '/app-icon', builder: (_, __) => const AppIconScreen()),
      GoRoute(path: '/secure-notes', builder: (_, __) => const SecureNotesScreen()),
      GoRoute(path: '/premium-library', builder: (_, __) => const PremiumAudioLibraryScreen()),
      GoRoute(path: '/profile-backup', builder: (_, __) => const ProfileBackupScreen()),
      GoRoute(path: '/alarm', builder: (_, __) => const AdhanAlarmScreen()),
      GoRoute(path: '/gamification', builder: (_, __) => const GamificationScreen()),
      GoRoute(path: '/traveler', builder: (_, __) => const TravelerModeScreen()),
      GoRoute(path: '/sleep', builder: (_, __) => const TahajjudSleepScreen()),
      GoRoute(path: '/zakat', builder: (_, __) => const ZakatScreen()),
      GoRoute(path: '/ayah-finder', builder: (_, __) => const AyahFinderScreen()),
      GoRoute(path: '/khutbah', builder: (_, __) => const KhutbahMoonScreen()),
      GoRoute(path: '/greeting-card', builder: (_, state) => GreetingCardScreen(initialImageUrl: state.extra as String?)),
      GoRoute(path: '/prayer-dnd', builder: (_, __) => const PrayerDndScreen()),
      GoRoute(path: '/women-calendar', builder: (_, __) => const WomenCalendarScreen()),
      GoRoute(path: '/media-center', builder: (_, __) => const MediaCenterScreen()),
      GoRoute(path: '/wallpapers', builder: (_, __) => const WallpaperGalleryScreen()),
      GoRoute(path: '/helpdesk', builder: (_, __) => const HelpdeskScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/qibla', builder: (_, __) => const QiblaScreen()),
      GoRoute(path: '/community', builder: (_, __) => const DuaBrotherhoodScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          AppStrings.format(
            AppStrings.pageNotFound,
            {'uri': state.uri},
          ),
        ),
      ),
    ),
  );
}
