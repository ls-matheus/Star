import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/material_ui.dart';

class StarAltTextTooltip extends StatelessWidget {
  const StarAltTextTooltip({
    required this.altText,
    required this.child,
    this.position = StarTooltipPosition.above,
    super.key,
  });

  final String altText;
  final Widget child;
  final StarTooltipPosition position;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final colors = context.colors;

    return Semantics(
      label: altText,
      child: StarTooltip(
        position: position,
        richMessage: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            altText,
            style: textStyles.bodySmall.copyWith(color: colors.textPrimary),
            softWrap: true,
          ),
        ),
        child: child,
      ),
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarAltTextTooltip')
Widget starAltTextTooltipPreview() {
  return StarAltTextTooltip(
    altText: 'User avatar showing a mountain landscape at sunset.',
    child: Container(width: 48, height: 48, color: const Color(0xFF3C45A5)),
  );
}
