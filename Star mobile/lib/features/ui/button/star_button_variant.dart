import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/material_ui.dart';

enum StarButtonVariant {
  primary,
  secondary,
  dangerPrimary,
  dangerSecondary,
  inverted,
  invertedOutline,
  ghost;

  Color fill(StarColorTheme colors) => switch (this) {
    primary => colors.brandPrimary,
    secondary => colors.buttonSecondaryFill,
    dangerPrimary => colors.buttonDangerFill,
    dangerSecondary => colors.buttonSecondaryFill,
    inverted => colors.buttonInvertedFill,
    invertedOutline => Colors.transparent,
    ghost => Colors.transparent,
  };

  Color activeFill(StarColorTheme colors) => switch (this) {
    primary => colors.brandSecondary,
    secondary => colors.buttonSecondaryActiveFill,
    dangerPrimary => colors.buttonDangerActiveFill,
    dangerSecondary => colors.buttonDangerOutlineActiveFill,
    inverted => colors.buttonInvertedFill,
    invertedOutline => colors.buttonOutlineActiveFill,
    ghost => colors.backgroundModifierHover,
  };

  Color textColor(StarColorTheme colors) => switch (this) {
    primary => colors.brandPrimaryFill,
    secondary => colors.buttonSecondaryText,
    dangerPrimary => colors.buttonDangerText,
    dangerSecondary => colors.buttonDangerOutlineText,
    inverted => colors.buttonInvertedText,
    invertedOutline => colors.buttonOutlineText,
    ghost => colors.buttonGhostText,
  };

  Color? borderColor(StarColorTheme colors, {bool hovered = false}) =>
      switch (this) {
        invertedOutline => colors.buttonOutlineBorder,
        _ when isStarMobileOs => null,
        primary => Color.lerp(
          Colors.white,
          hovered ? colors.brandSecondary : colors.brandPrimary,
          hovered ? 0.84 : 0.82,
        ),
        secondary || dangerSecondary =>
          hovered
              ? Color.lerp(
                  colors.textTertiary,
                  colors.backgroundModifierAccent,
                  0.88,
                )
              : colors.backgroundModifierAccent,
        _ => null,
      };

  Border? border(StarColorTheme colors, {bool hovered = false}) {
    final Color? color = borderColor(colors, hovered: hovered);
    return color == null ? null : Border.all(color: color);
  }
}
