import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/material_ui.dart';

BoxDecoration guildDiscoveryCardDecoration(
  StarColorTheme colors,
  StarLayoutTheme layout,
) {
  return BoxDecoration(
    color: colors.backgroundSecondary,
    borderRadius: layout.radiusSm,
    border: Border.all(color: colors.backgroundHeaderSecondary),
  );
}
