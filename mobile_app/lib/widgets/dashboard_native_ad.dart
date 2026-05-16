import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/services/ads/ad_service.dart';
import '../core/services/purchase_service.dart';
import '../core/theme/app_theme.dart';

class DashboardNativeAd extends StatefulWidget {
  const DashboardNativeAd(
        factoryId: 'huzur_glass_native',{super.key});

  static const screenKey = 'dashboard_native_ad';

  @override
  State<DashboardNativeAd> createState() => _DashboardNativeAdState();
}

class _DashboardNativeAdState extends State<DashboardNativeAd> {
  NativeAd? _nativeAd;
  bool _loaded = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isPremium = context.watch<PurchaseService>().isPremium;
    final adsGloballyDisabled = context.watch<AdService>().globallyDisabled;

    if (isPremium || adsGloballyDisabled) {
      _disposeAd();
      return;
    }

    if (!_loading && _nativeAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    _loading = true;

    final ad = NativeAd(
      adUnitId: context.read<AdService>().nativeUnitId(context),
      factoryId: 'dashboardNativeAd',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _nativeAd = ad as NativeAd;
            _loaded = true;
            _loading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;

          setState(() {
            _nativeAd = null;
            _loaded = false;
            _loading = false;
          });
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppTheme.emerald,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.ink,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 16,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.ink.withOpacity(.68),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.ink.withOpacity(.52),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
      ),
    );

    ad.load();
  }

  void _disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _loaded = false;
    _loading = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseService>().isPremium;
    final adsGloballyDisabled = context.watch<AdService>().globallyDisabled;
    final ad = _nativeAd;

    if (isPremium || adsGloballyDisabled) {
      return const SizedBox.shrink();
    }

    if (!_loaded || ad == null) {
      return const _NativeAdShell(
        child: SizedBox(
          height: 150,
          child: Center(
            child: Text(
              AppStrings.dashboardNativeAdLoading,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
    }

    return _NativeAdShell(
      child: SizedBox(
        height: 320,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}

class _NativeAdShell extends StatelessWidget {
  final Widget child;

  const _NativeAdShell({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14231F).withOpacity(.86) : Colors.white.withOpacity(.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? Colors.white.withOpacity(.08) : AppTheme.ink.withOpacity(.05),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emerald.withOpacity(dark ? .14 : .10),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  AppStrings.sponsored,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.gold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.verified_rounded,
                size: 18,
                color: AppTheme.emerald.withOpacity(.78),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
