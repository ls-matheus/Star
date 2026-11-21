import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';

typedef SelectedReactionChipColors = ({
  Color background,
  Color hover,
  Color border,
  Color foreground,
});

SelectedReactionChipColors selectedReactionChipColorsFor(
  StarColorTheme colors, {
  required Brightness brightness,
  Color? surface,
}) {
  if (brightness == Brightness.light) {
    return (
      background: Color.lerp(
        surface ?? colors.backgroundPrimary,
        colors.brandPrimary,
        0.12,
      )!,
      hover: Color.lerp(
        surface ?? colors.backgroundPrimary,
        colors.brandPrimary,
        0.18,
      )!,
      border: colors.brandPrimary.withValues(alpha: 0.45),
      foreground: colors.brandPrimary,
    );
  }
  return (
    background: Color.lerp(
      surface ?? colors.backgroundSecondary,
      colors.brandPrimary,
      0.36,
    )!,
    hover: Color.lerp(
      surface ?? colors.backgroundSecondary,
      colors.brandPrimary,
      0.48,
    )!,
    border: colors.brandPrimary,
    foreground: colors.textOnBrandPrimary,
  );
}

SelectedReactionChipColors selectedReactionChipColors(
  BuildContext context, {
  Color? surface,
}) {
  return selectedReactionChipColorsFor(
    context.colors,
    brightness: Theme.of(context).brightness,
    surface: surface,
  );
}
