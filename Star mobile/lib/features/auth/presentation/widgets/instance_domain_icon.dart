import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class InstanceDomainIcon extends StatelessWidget {
  const InstanceDomainIcon({
    required this.isOfficial,
    this.size = 12,
    super.key,
  });

  final bool isOfficial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (isOfficial) {
      return PhosphorIcon(
        PhosphorIconsFill.sealCheck,
        size: size,
        color: colors.textTertiary,
      );
    }
    return PhosphorIcon(
      PhosphorIconsFill.globe,
      size: size,
      color: colors.textTertiary,
    );
  }
}
