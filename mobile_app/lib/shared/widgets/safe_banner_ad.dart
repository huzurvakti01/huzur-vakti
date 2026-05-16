import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../core/services/ads/ad_service.dart';
import '../../core/services/kids_mode_service.dart';
import '../../core/services/purchase_service.dart';

class SafeBannerAd extends StatefulWidget {
  final String screenKey;

  const SafeBannerAd({
    super.key,
    required this.screenKey,
  });

  @override
  State<SafeBannerAd> createState() => _SafeBannerAdState();
}

class _SafeBannerAdState extends State<SafeBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _lastAllowed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

      context.watch<PurchaseService>().isPremium;
    context.watch<KidsModeService>().enabled;
    context.watch<AdService>().globallyDisabled;

    final service = context.read<AdService>();
    final allowed = service.canShowBanner(context: context, screenKey: widget.screenKey);

    if (!allowed) {
      _disposeAd();
      _lastAllowed = false;
      return;
    }

    if (_ad == null || !_lastAllowed) {
      _disposeAd();
      _lastAllowed = true;
      _ad = service.createBanner(context)
        ..load().then((_) {
          if (mounted) setState(() => _loaded = true);
        });
    }
  }

  void _disposeAd() {
    _loaded = false;
    _lastAllowed = false;
    _ad?.dispose();
    _ad = null;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
