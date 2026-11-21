import 'package:star_app/core/theme/star_fonts.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';

TextStyle profileBadgeCaptionTextStyle(
  BuildContext context, {
  required double fontSize,
}) {
  final colors = context.colors;
  final bool isLight = Theme.of(context).brightness == Brightness.light;
  return TextStyle(
    fontFamily: StarFonts.sans,
    color: isLight ? colors.textLink : colors.brandPrimaryLight,
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    height: 1,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}
