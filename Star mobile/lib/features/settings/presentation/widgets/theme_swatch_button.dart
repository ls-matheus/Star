import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/selected_check/star_selected_check.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

class ThemeSwatchButton extends StatelessWidget {
  const ThemeSwatchButton({
    required this.label,
    required this.backgroundColor,
    required this.isSelected,
    required this.onTap,
    this.centerIcon,
    this.enabled = true,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? centerIcon;
  final bool enabled;
  final bool isLoading;

  static const double _size = 56;
  static const double _checkmarkSize = 20;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool desktop = usesDesktopPointerUi(context);
    final onLightBackground = _estimateLuminance(backgroundColor) > 0.5;
    final contrastColor = onLightBackground ? Colors.black : Colors.white;
    final borderColor = isSelected
        ? colors.brandPrimary
        : onLightBackground
        ? colors.borderColor
        : desktop
        ? Colors.white
        : colors.textPrimary;

    final interactive = enabled && !isLoading;

    return StarTooltip(
      message: label,
      child: Semantics(
        selected: isSelected,
        button: true,
        enabled: interactive,
        child: Opacity(
          opacity: enabled
              ? 1
              : desktop
              ? 0.48
              : 0.4,
          child: SizedBox(
            width: _size,
            height: _size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Material(
                    color: backgroundColor,
                    shape: CircleBorder(
                      side: BorderSide(color: borderColor, width: 2),
                    ),
                    child: InkWell(
                      onTap: interactive ? onTap : null,
                      customBorder: const CircleBorder(),
                      splashFactory: desktop ? NoSplash.splashFactory : null,
                      highlightColor: desktop ? Colors.transparent : null,
                      hoverColor: desktop ? Colors.transparent : null,
                      mouseCursor: desktop && !interactive
                          ? SystemMouseCursors.forbidden
                          : null,
                      child: isLoading
                          ? Center(
                              child: StarLoadingSpinner(
                                color: contrastColor,
                                size: StarLoadingSpinnerSize.small,
                              ),
                            )
                          : centerIcon == null
                          ? const SizedBox.expand()
                          : Center(
                              child: PhosphorIcon(
                                centerIcon!,
                                size: 24,
                                color: contrastColor,
                              ),
                            ),
                    ),
                  ),
                ),
                if (isSelected && !isLoading)
                  const PositionedDirectional(
                    top: -4,
                    end: -4,
                    child: StarSelectedCheck(size: _checkmarkSize),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _estimateLuminance(Color color) {
    return (0.299 * (color.r * 255) +
            0.587 * (color.g * 255) +
            0.114 * (color.b * 255)) /
        255;
  }
}
