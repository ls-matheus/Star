import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class StarSelectedCheck extends StatelessWidget {
  const StarSelectedCheck({this.size = 22, this.borderColor, super.key});

  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color? ring = borderColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.brandPrimary,
        border: ring == null ? null : Border.all(color: ring, width: 2),
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(
        PhosphorIconsBold.check,
        size: size * 0.58,
        color: colors.brandPrimaryFill,
      ),
    );
  }
}
