import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_app/core/constants/assets.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';

class SettingsStarLogoIcon extends StatelessWidget {
  const SettingsStarLogoIcon({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color =
        IconTheme.of(context).color ?? context.colors.textPrimary;
    return ExcludeSemantics(
      child: SvgPicture.asset(
        Assets.starLogoMonochrome,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
