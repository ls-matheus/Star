import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

class StarFocusRing extends StatelessWidget {
  const StarFocusRing({
    required this.focused,
    required this.child,
    this.borderRadius,
    super.key,
  });

  final bool focused;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final motion = context.motion;
    final resolvedRadius = borderRadius ?? layout.radiusMd;

    if (usesDesktopPointerUi(context)) {
      return AnimatedContainer(
        duration: Duration.zero,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? layout.radiusSm,
          boxShadow: focused
              ? [BoxShadow(color: colors.focusPrimary, spreadRadius: 4)]
              : const [],
        ),
        child: child,
      );
    }

    return AnimatedContainer(
      duration: motion.fast,
      curve: motion.curve,
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        boxShadow: focused
            ? [
                BoxShadow(
                  color: colors.focusPrimary.withValues(alpha: 0.45),
                  spreadRadius: 2,
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }
}

@StarWidgetPreview(name: 'Unfocused', group: 'StarFocusRing')
Widget starFocusRingOffPreview() {
  return StarFocusRing(
    focused: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text('Focus target'),
    ),
  );
}

@StarWidgetPreview(name: 'Focused', group: 'StarFocusRing')
Widget starFocusRingOnPreview() {
  return StarFocusRing(
    focused: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text('Focus target'),
    ),
  );
}
