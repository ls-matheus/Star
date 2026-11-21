import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';

class StarSettingsStatusBadge extends StatelessWidget {
  const StarSettingsStatusBadge.experimental({super.key});

  String get text => 'EXPERIMENTAL';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.brandPrimary,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            text,
            maxLines: 1,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.brandPrimaryFill,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class StarLabelWithBadge extends StatelessWidget {
  const StarLabelWithBadge({required this.label, this.badge, super.key});

  final Widget label;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = badge;
    if (trailing == null) {
      return label;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(child: label),
        const SizedBox(width: 6),
        trailing,
      ],
    );
  }
}
