import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_god_mode_resolver.dart';

class DynamicSplashImage extends StatelessWidget {
  final double width;
  final BoxFit fit;

  const DynamicSplashImage({
    super.key,
    this.width = 132,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final resolver = context.watch<AppGodModeResolver>();
    final url = resolver.splashImageUrl.isNotEmpty
        ? resolver.splashImageUrl
        : resolver.logoUrl;

    if (url.isEmpty) {
      return Image.asset(
        'assets/images/logo_main.png',
        width: width,
        fit: fit,
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      fit: fit,
      placeholder: (context, _) => Image.asset('assets/images/logo_main.png', width: width, fit: fit),
      errorWidget: (context, _, __) => Image.asset('assets/images/logo_main.png', width: width, fit: fit),
    );
  }
}
