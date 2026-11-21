import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/material_ui.dart';

const Duration starToastAnimationDuration = StarMotionTheme.panelDuration;

enum StarToastVariant { info, success, warning, danger }

class StarToastAction {
  const StarToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

class StarToast {
  const StarToast({
    required this.message,
    this.variant = StarToastVariant.info,
    this.duration = const Duration(seconds: 4),
    this.action,
    this.leading,
  });

  final String message;
  final StarToastVariant variant;
  final Duration duration;
  final StarToastAction? action;
  final Widget? leading;
}
