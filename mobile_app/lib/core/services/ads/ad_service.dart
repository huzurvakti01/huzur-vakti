import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../logging/app_logger.dart';
import '../kids_mode_service.dart';
import '../purchase_service.dart';

class AdService extends ChangeNotifier {
  static const int frequency = 4;

  int _counter = 0;
  bool _loadingInterstitial = false;
  bool _showingInterstitial = false;
  bool _globallyDisabled = false;
  InterstitialAd? _interstitialAd;

  bool get globallyDisabled => _globallyDisabled;

  void syncGlobalAdState({
    required bool isPremium,
    required bool isKidsMode,
  }) {
    final disabled = isPremium || isKidsMode;
    if (_globallyDisabled == disabled) return;

    _globallyDisabled = disabled;

    if (disabled) {
      reset();
    }

    notifyListeners();
  }

  bool adsDisabled(BuildContext context) {
    try {
      final premium = context.read<PurchaseService>().isPremium;
      final kids = context.read<KidsModeService>().enabled;
      return _globallyDisabled || premium || kids;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Ad dependency lookup failed',
        error: error,
        stackTrace: stackTrace,
      );
      return _globallyDisabled;
    }
  }

  bool isSensitive(String key) {
    return AppConstants.sensitiveNoInterstitialScreens.contains(_normalize(key));
  }

  bool canShowBanner({
    required BuildContext context,
    required String screenKey,
  }) {
    if (adsDisabled(context)) return false;
    if (isSensitive(screenKey)) return false;
    return true;
  }

  void trackNavigation({
    required BuildContext context,
    required String fromScreenKey,
    required String toScreenKey,
  }) {
    if (adsDisabled(context)) {
      reset();
      return;
    }

    final from = _normalize(fromScreenKey);
    final to = _normalize(toScreenKey);

    if (isSensitive(from) || isSensitive(to)) {
      preload(context);
      return;
    }

    _counter++;
    if (_counter >= frequency) {
      _counter = 0;
      showInterstitialIfReady(context);
    } else {
      preload(context);
    }
  }

  void trackButtonTap({
    required BuildContext context,
    required String currentScreenKey,
    String? targetScreenKey,
  }) {
    trackNavigation(
      context: context,
      fromScreenKey: currentScreenKey,
      toScreenKey: targetScreenKey ?? currentScreenKey,
    );
  }

  void trackCompletedAction({
    required BuildContext context,
    required String screenKey,
  }) {
    if (adsDisabled(context)) {
      reset();
      return;
    }

    final current = _normalize(screenKey);
    if (isSensitive(current)) {
      preload(context);
      return;
    }

    _counter++;
    if (_counter >= frequency) {
      _counter = 0;
      showInterstitialIfReady(context);
    } else {
      preload(context);
    }
  }

  void preload(BuildContext context) {
    if (adsDisabled(context)) {
      reset();
      return;
    }
    if (_interstitialAd != null || _loadingInterstitial) return;

    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;

          if (adsDisabled(context)) {
            ad.dispose();
            return;
          }

          _interstitialAd = ad;
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _showingInterstitial = false;
              _interstitialAd = null;
              preload(context);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _showingInterstitial = false;
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (_) {
          _loadingInterstitial = false;
        },
      ),
    );
  }

  void showInterstitialIfReady(BuildContext context) {
    if (adsDisabled(context) || _showingInterstitial) return;

    final ad = _interstitialAd;
    if (ad == null) {
      preload(context);
      return;
    }

    _showingInterstitial = true;
    _interstitialAd = null;
    ad.show();
  }

  BannerAd createBanner(BuildContext context) {
    return BannerAd(
      adUnitId: bannerUnitId(context),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }

  String bannerUnitId(BuildContext context) {
    final android = defaultTargetPlatform == TargetPlatform.android;
    return android
        ? (dotenv.env['ADMOB_ANDROID_BANNER_ID'] ??
            'ca-app-pub-3940256099942544/6300978111')
        : (dotenv.env['ADMOB_IOS_BANNER_ID'] ??
            'ca-app-pub-3940256099942544/2934735716');
  }

  String nativeUnitId(BuildContext context) {
    final android = defaultTargetPlatform == TargetPlatform.android;
    return android
        ? (dotenv.env['ADMOB_ANDROID_NATIVE_ID'] ??
            'ca-app-pub-3940256099942544/2247696110')
        : (dotenv.env['ADMOB_IOS_NATIVE_ID'] ??
            'ca-app-pub-3940256099942544/3986624511');
  }

  String interstitialUnitId() {
    final android = defaultTargetPlatform == TargetPlatform.android;
    return android
        ? (dotenv.env['ADMOB_ANDROID_INTERSTITIAL_ID'] ??
            'ca-app-pub-3940256099942544/1033173712')
        : (dotenv.env['ADMOB_IOS_INTERSTITIAL_ID'] ??
            'ca-app-pub-3940256099942544/4411468910');
  }

  void reset() {
    _counter = 0;
    _loadingInterstitial = false;
    _showingInterstitial = false;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  String _normalize(String key) => key.trim().toLowerCase().replaceAll(' ', '_');

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
