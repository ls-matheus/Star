import 'package:flutter/widgets.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';

abstract final class ShellTransitionPolicy {
  const ShellTransitionPolicy._();

  static Duration rootOverlayFadeDuration(BuildContext context) =>
      context.motion.normal;
}
