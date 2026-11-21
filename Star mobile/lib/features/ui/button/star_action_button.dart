import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

enum StarActionButtonVariant { defaultStyle, danger }

class StarActionButton extends StatelessWidget {
  const StarActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isDisabled = false,
    this.variant = StarActionButtonVariant.defaultStyle,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDisabled;
  final StarActionButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDanger = variant == StarActionButtonVariant.danger;

    final Color background;
    final Color foreground;
    final Color labelColor;
    if (isActive) {
      background = isDanger ? colors.statusDanger : colors.brandPrimary;
      foreground = Colors.white;
      labelColor = Colors.white;
    } else {
      background = StarBottomSheet.cardColorOf(context);
      foreground = isDanger ? colors.statusDanger : colors.textPrimary;
      labelColor = isDanger ? colors.statusDanger : colors.textSecondary;
    }

    return Opacity(
      opacity: isDisabled ? 0.5 : 1,
      child: StarTappable(
        onTap: isDisabled ? null : onTap,
        semanticLabel: label,
        builder: (context, states) => Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(icon, size: 20, color: foreground),
              const SizedBox(height: 4),
              Text(
                label,
                style: context.textStyles.label.copyWith(color: labelColor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarActionButton')
Widget starActionButtonDefaultPreview() {
  return SizedBox(
    width: 96,
    child: StarActionButton(
      icon: PhosphorIconsBold.bellSlash,
      label: 'Mute',
      onTap: () {},
    ),
  );
}

@StarWidgetPreview(name: 'Active', group: 'StarActionButton')
Widget starActionButtonActivePreview() {
  return SizedBox(
    width: 96,
    child: StarActionButton(
      icon: PhosphorIconsBold.bellSlash,
      label: 'Unmute',
      isActive: true,
      onTap: () {},
    ),
  );
}
