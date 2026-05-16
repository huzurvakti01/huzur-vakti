import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_god_mode_resolver.dart';

class DynamicBrandLogo extends StatelessWidget {
  final double width;
  final bool whiteFallback;
  final BoxFit fit;

  const DynamicBrandLogo({
    super.key,
    this.width = 120,
    this.whiteFallback = false,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final resolver = context.watch<AppGodModeResolver>();
    final logoUrl = resolver.logoUrl;
    final localFallback = whiteFallback
        ? 'assets/images/logo_white.png'
        : 'assets/images/logo_main.png';

    if (logoUrl.isEmpty) {
      return Image.asset(
        localFallback,
        width: width,
        fit: fit,
      );
    }

    return CachedNetworkImage(
      imageUrl: logoUrl,
      width: width,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 220),
      fadeOutDuration: const Duration(milliseconds: 140),
      placeholder: (context, url) => Image.asset(
        localFallback,
        width: width,
        fit: fit,
      ),
      errorWidget: (context, url, error) => Image.asset(
        localFallback,
        width: width,
        fit: fit,
      ),
    );
  }
}
