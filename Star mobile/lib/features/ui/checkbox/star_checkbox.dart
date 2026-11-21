import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/radio_group/star_radio_group.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

class StarCheckbox extends StatelessWidget {
  const StarCheckbox({
    required this.value,
    required this.onChanged,
    this.label,
    this.child,
    this.enabled = true,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? label;
  final Widget? child;
  final bool enabled;

  String? get _semanticsLabel {
    if (label != null) {
      return label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    if (usesDesktopPointerUi(context)) {
      return _buildDesktop(context);
    }

    return StarTappable(
      enabled: enabled,
      onTap: () => onChanged(!value),
      semanticLabel: _semanticsLabel,
      checked: value,
      excludeChildSemantics: _semanticsLabel != null,
      builder: (context, states) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: ExcludeSemantics(
                child: Checkbox(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            if (child != null || label != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child:
                    child ??
                    Text(
                      label!,
                      style: textStyles.bodySmall.copyWith(
                        color: enabled
                            ? colors.textPrimary
                            : colors.textTertiary,
                      ),
                    ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final colors = context.colors;
    final Color uncheckedBorder = starRadioRingColor(context);
    final Widget box = Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value ? colors.brandPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: value ? colors.brandPrimary : uncheckedBorder,
        ),
      ),
      child: value
          ? PhosphorIcon(
              PhosphorIconsBold.check,
              size: 18,
              color: colors.brandPrimaryFill,
            )
          : null,
    );
    final bool hasLabel = child != null || label != null;
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: box),
        if (hasLabel)
          Flexible(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, top: 1),
              child: DefaultTextStyle.merge(
                style: context.textStyles.bodySmall.copyWith(
                  color: colors.textPrimary,
                  height: 20 / 14,
                ),
                child:
                    child ??
                    Text(
                      label!,
                      style: context.textStyles.bodySmall.copyWith(
                        color: colors.textPrimary,
                        height: 20 / 14,
                      ),
                    ),
              ),
            ),
          ),
      ],
    );
    return StarTappable(
      enabled: enabled,
      onTap: () => onChanged(!value),
      semanticLabel: _semanticsLabel,
      checked: value,
      excludeChildSemantics: _semanticsLabel != null,
      builder: (context, states) => content,
    );
  }
}

@StarWidgetPreview(name: 'Unchecked', group: 'StarCheckbox')
Widget starCheckboxUncheckedPreview() {
  return StarCheckbox(
    value: false,
    onChanged: (_) {},
    label: 'Enable desktop notifications',
  );
}

@StarWidgetPreview(name: 'Checked', group: 'StarCheckbox')
Widget starCheckboxCheckedPreview() {
  return StarCheckbox(
    value: true,
    onChanged: (_) {},
    label: 'Enable desktop notifications',
  );
}
