import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_god_mode_resolver.dart';

class GodModeText extends StatelessWidget {
  final String cloudKey;
  final String fallback;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const GodModeText(
    this.cloudKey,
    this.fallback, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final resolver = context.watch<AppGodModeResolver>();

    return Text(
      resolver.text(cloudKey, fallback),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
