import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button_variant.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class StarCircleFab extends StatelessWidget {
  const StarCircleFab({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    return StarTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      builder: (BuildContext context, Set<WidgetState> states) {
        final colors = context.colors;
        final motion = context.motion;
        final bool isHovered = states.contains(WidgetState.hovered);

        return AnimatedContainer(
          duration: motion.fast,
          curve: motion.curve,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isHovered ? colors.brandSecondary : colors.brandPrimary,
            shape: BoxShape.circle,
            border: StarButtonVariant.primary.border(
              colors,
              hovered: isHovered,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: PhosphorIcon(icon, size: 24, color: colors.textOnBrandPrimary),
        );
      },
    );
  }
}
