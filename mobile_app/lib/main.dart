import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'core/config/app_god_mode_resolver.dart';
import 'core/errors/app_exception.dart';
import 'core/logging/app_logger.dart';
import 'core/routing/app_router.dart';
import 'core/services/ad_consent_service.dart';
import 'core/services/ads/ad_service.dart';
import 'core/services/ai_client_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/data_repository_hub.dart';
import 'core/services/ai_chat_service.dart';
import 'core/services/app_icon_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/alarm_service.dart';
import 'core/services/audio/adhan_audio_service.dart';
import 'core/services/background_alarm_manager.dart';
import 'core/services/background_alarm_scheduler.dart';
import 'core/services/dua_brotherhood_service.dart';
import 'core/services/finance_rate_service.dart';
import 'core/services/kids_mode_service.dart';
import 'core/services/media_center_service.dart';
import 'core/services/women_calendar_service.dart';
import 'core/services/prayer_dnd_service.dart';
import 'core/services/greeting_card_service.dart';
import 'core/services/ayah_finder_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/prayer_api_service.dart';
import 'core/services/purchase_service.dart';
import 'core/services/revenuecat_service.dart';
import 'core/services/global_settings_service.dart';
import 'core/services/consent_service.dart';
import 'core/services/gallery_service.dart';
import 'core/services/helpdesk_service.dart';
import 'core/services/quran_audio_service.dart';
import 'core/services/religious_content_service.dart';
import 'core/services/quran_api_service.dart';
import 'core/services/gamification_service.dart';
import 'core/services/secure_notes_service.dart';
import 'core/services/biometric_lock_service.dart';
import 'core/services/cloud_sync_service.dart';
import 'core/services/hard_wake_service.dart';
import 'core/services/qibla_service.dart';
import 'core/services/tahajjud_service.dart';
import 'core/services/traveler_mode_service.dart';
import 'core/services/widget_bridge_service.dart';
import 'core/services/zakat_service.dart';
import 'core/state/prayer_controller.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await _safeInit(
    label: 'dotenv',
    action: () => dotenv.load(fileName: '.env'),
    fallback: () => dotenv.load(fileName: '.env.example'),
  );

  await _safeInit(
    label: 'firebase',
    action: () => Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    fatal: false,
  );

  await _safeInit(
    label: 'mobile_ads',
    action: MobileAds.instance.initialize,
    fatal: false,
  );

  final godModeResolver = AppGodModeResolver();

  await _safeInit(
    label: 'god_mode_resolver',
    action: godModeResolver.init,
    fatal: false,
  );

  final notificationService = NotificationService();
  await _safeInit(
    label: 'local_notifications',
    action: notificationService.init,
    fatal: false,
  );

  final adhanAudioService = AdhanAudioService();
  final widgetBridgeService = WidgetBridgeService();
  final womenCalendarService = WomenCalendarService();
  final globalSettingsService = GlobalSettingsService();
  final crashReportingService = CrashReportingService();
  final analyticsService = AnalyticsService();
  final adConsentService = AdConsentService();
  final backgroundAlarmManager = BackgroundAlarmManager();
  await _safeInit(
    label: 'widget_bridge',
    action: widgetBridgeService.init,
    fatal: false,
  );

  await _safeInit(
    label: 'women_calendar_hive',
    action: womenCalendarService.init,
    fatal: false,
  );

  await _safeInit(
    label: 'global_settings',
    action: globalSettingsService.init,
    fatal: false,
  );

  await _safeInit(
    label: 'crashlytics',
    action: crashReportingService.init,
    fatal: false,
  );

  await _safeInit(
    label: 'analytics_app_open',
    action: analyticsService.logAppOpen,
    fatal: false,
  );

  await _safeInit(
    label: 'admob_ump_consent_first_launch',
    action: adConsentService.requestConsentOnFirstLaunch,
    fatal: false,
  );

  FlutterError.onError = (details) {
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
      context: {'library': details.library},
    );
  };

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('ar'), Locale('fr'), Locale('ur'), Locale('id')],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr'),
      child: HuzurVaktiApp(
        notificationService: notificationService,
        adhanAudioService: adhanAudioService,
        widgetBridgeService: widgetBridgeService,
        womenCalendarService: womenCalendarService,
        globalSettingsService: globalSettingsService,
        godModeResolver: godModeResolver,
        crashReportingService: crashReportingService,
        analyticsService: analyticsService,
      ),
    ),
  );
}

Future<void> _safeInit({
  required String label,
  required Future<void> Function() action,
  Future<void> Function()? fallback,
  bool fatal = false,
}) async {
  try {
    await action();
    AppLogger.info('Startup step completed', context: {'step': label});
  } catch (error, stackTrace) {
    AppLogger.error(
      'Startup step failed',
      error: error,
      stackTrace: stackTrace,
      context: {'step': label},
    );

    if (fallback != null) {
      try {
        await fallback();
        AppLogger.info('Startup fallback completed', context: {'step': label});
        return;
      } catch (fallbackError, fallbackStackTrace) {
        AppLogger.error(
          'Startup fallback failed',
          error: fallbackError,
          stackTrace: fallbackStackTrace,
          context: {'step': label},
        );
      }
    }

    if (fatal) {
      throw AppException(
        'Uygulama başlatılamadı.',
        cause: error,
        stackTrace: stackTrace,
        code: 'startup_failed',
      );
    }
  }
}

class HuzurVaktiApp extends StatelessWidget {
  final NotificationService notificationService;
  final AdhanAudioService adhanAudioService;
  final WidgetBridgeService widgetBridgeService;
  final WomenCalendarService womenCalendarService;
  final GlobalSettingsService globalSettingsService;
  final AppGodModeResolver godModeResolver;
  final CrashReportingService crashReportingService;
  final AnalyticsService analyticsService;

  const HuzurVaktiApp({
    super.key,
    required this.notificationService,
    required this.adhanAudioService,
    required this.widgetBridgeService,
    required this.womenCalendarService,
    required this.globalSettingsService,
    required this.godModeResolver,
    required this.crashReportingService,
    required this.analyticsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => DataRepositoryHub()),
        Provider(create: (_) => PrayerApiService()),
        Provider(create: (_) => AppIconService()),
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        Provider(create: (_) => BiometricLockService()),
        Provider(create: (_) => SecureNotesService()),
        Provider(create: (_) => CloudSyncService()),
        ChangeNotifierProvider(create: (_) => HardWakeService()..load()),
        Provider(create: (_) => QuranApiService()),
        Provider(create: (_) => FinanceRateService()),
        Provider(create: (_) => LocationService()),
        Provider(create: (context) => QiblaService(locationService: context.read<LocationService>())),
        Provider(create: (_) => widgetBridgeService),
        Provider(create: (_) => womenCalendarService),
        ChangeNotifierProvider(create: (_) => globalSettingsService),
        ChangeNotifierProvider(create: (_) => godModeResolver),
        Provider(create: (_) => ConsentService()),
        Provider<Object?>(create: (_) => null),
        Provider(create: (_) => analyticsService),
        Provider(create: (_) => crashReportingService),
        Provider(create: (_) => MediaCenterService()),
        Provider(create: (_) => PrayerDndService()),
        Provider(create: (_) => GreetingCardService()),
        Provider(create: (_) => AyahFinderService()),
        Provider(create: (_) => GalleryService()),
        Provider(create: (_) => HelpdeskService()),
        Provider(create: (_) => QuranAudioService()),
        Provider(create: (_) => ReligiousContentService()),
        Provider(create: (_) => notificationService),
        Provider<Object?>(create: (_) => null),
        Provider(create: (_) => BackgroundAlarmScheduler(manager: null)),
        Provider(create: (_) => adhanAudioService),
        ChangeNotifierProvider(create: (_) => AdService()),
        Provider(create: (_) => DuaBrotherhoodService()),
        Provider(create: (_) => TahajjudService()),
        Provider(create: (_) => ZakatService()),
        ChangeNotifierProvider(create: (_) => PurchaseService()..init()),
        ProxyProvider2<PurchaseService, AnalyticsService, AiClientService>(
          update: (context, purchase, analytics, previous) => AiClientService(
            purchaseService: purchase,
            analytics: analytics,
          ),
        ),
        ProxyProvider<AiClientService, AiChatService>(
          update: (context, secureClient, previous) => AiChatService(
            secureClient: secureClient,
          ),
        ),
        ChangeNotifierProvider(create: (_) => RevenueCatService()..init()),
        ChangeNotifierProvider(create: (_) => KidsModeService()..load()),
        ChangeNotifierProxyProvider<AuthService, GamificationService>(
          create: (context) => GamificationService(
            cloudSyncService: context.read<CloudSyncService>(),
          )..load(),
          update: (context, auth, service) {
            final instance = service ??
                GamificationService(
                  cloudSyncService: context.read<CloudSyncService>(),
                )..load();

            instance.syncAuthState(auth.user);
            return instance;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => TravelerModeService(
            locationService: context.read<LocationService>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => AlarmService(
            audioService: context.read<AdhanAudioService>(),
            notificationService: context.read<NotificationService>(),
            backgroundScheduler: context.read<BackgroundAlarmScheduler>(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => PrayerController(
            api: context.read<PrayerApiService>(),
            locationService: context.read<LocationService>(),
            widgetBridge: context.read<WidgetBridgeService>(),
            alarmService: context.read<AlarmService>(),
            globalSettings: context.read<GlobalSettingsService>(),
          )..load(),
        ),
      ],
      child: Consumer4<KidsModeService, PurchaseService, AdService, AppGodModeResolver>(
        builder: (context, kids, purchase, ads, godMode, _) {
          ads.syncGlobalAdState(
            isPremium: purchase.isPremium,
            isKidsMode: kids.enabled,
          );

          return MaterialApp.router(
            title: 'Huzur Vakti',
            debugShowCheckedModeBanner: false,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: kids.enabled ? KidsTheme.light() : godMode.applyDynamicTheme(AppTheme.light()),
            darkTheme: kids.enabled ? KidsTheme.dark() : godMode.applyDynamicTheme(AppTheme.dark()),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
