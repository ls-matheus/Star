import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart'
    show isMobileLayout;
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/features/ui/toggle_switch/star_switch_control.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_app/shared/utils/star_haptics.dart';

class StarToggleSwitch extends StatelessWidget {
  const StarToggleSwitch({
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.icon,
    this.enabled = true,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? description;
  final IconData? icon;
  final bool enabled;

  String? _semanticsLabel() {
    if (label == null) {
      return description;
    }
    if (description == null) {
      return label;
    }
    return '$label. $description';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    final hasContent = label != null || description != null || icon != null;

    if (label != null &&
        (isMobileLayout(context) || StarMenuGroup.isGrouped(context))) {
      return StarMenuGroup.ensureGrouped(
        context,
        StarBottomSheetMenuItem(
          label: label!,
          hint: description,
          icon: icon,
          enabled: enabled,
          toggled: value,
          onTap: () {
            StarHaptics.selection();
            onChanged(!value);
          },
          trailing: StarSwitchControl(value: value, enabled: enabled),
        ),
      );
    }

    if (usesDesktopPointerUi(context)) {
      return _buildDesktop(context, hasContent);
    }

    Widget buildLabelContent(BuildContext context, Set<WidgetState> _) {
      final foreground = enabled ? colors.textPrimary : colors.textTertiary;

      return Padding(
        padding: EdgeInsets.symmetric(vertical: layout.s1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Padding(
                padding: EdgeInsets.only(top: layout.s1 / 2),
                child: Icon(icon, size: 18, color: foreground),
              ),
              SizedBox(width: layout.s2),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: textStyles.bodyMedium.copyWith(color: foreground),
                    ),
                  if (description != null) ...[
                    if (label != null) SizedBox(height: layout.s1 / 2),
                    Text(
                      description!,
                      style: textStyles.bodySmall.copyWith(
                        color: enabled
                            ? colors.textSecondary
                            : colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return StarTappable(
      enabled: enabled,
      minSize: Size(layout.touchTargetMin, layout.touchTargetMin),
      onTap: () {
        StarHaptics.selection();
        onChanged(!value);
      },
      semanticLabel: _semanticsLabel(),
      toggled: value,
      excludeChildSemantics: _semanticsLabel() != null,
      builder: (context, states) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasContent) ...[
              Expanded(child: buildLabelContent(context, states)),
              SizedBox(width: layout.s4),
            ],
            StarSwitchControl(value: value, enabled: enabled),
          ],
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context, bool hasContent) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final TextStyle base = textStyles.bodySmall.copyWith(
      fontSize: 14,
      height: 20 / 14,
    );
    return StarTappable(
      enabled: enabled,
      onTap: () {
        StarHaptics.selection();
        onChanged(!value);
      },
      semanticLabel: _semanticsLabel(),
      toggled: value,
      excludeChildSemantics: _semanticsLabel() != null,
      builder: (context, states) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                if (hasContent)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        if (label != null || icon != null)
                          Row(
                            spacing: 8,
                            children: [
                              if (icon != null)
                                Icon(icon, size: 18, color: colors.textPrimary),
                              if (label != null)
                                Flexible(
                                  child: Text(
                                    label!,
                                    style: base.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        if (description != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 16),
                            child: Text(
                              description!,
                              style: base.copyWith(
                                color: colors.textPrimaryMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                StarSwitchControl(value: value, enabled: enabled),
              ],
            ),
          ),
        );
      },
    );
  }
}

@StarWidgetPreview(name: 'Off', group: 'StarToggleSwitch')
Widget starToggleSwitchOffPreview() {
  return StarToggleSwitch(
    value: false,
    onChanged: (_) {},
    label: 'Compact mode',
    description: 'Use a denser layout in the sidebar.',
  );
}

@StarWidgetPreview(name: 'On', group: 'StarToggleSwitch')
Widget starToggleSwitchOnPreview() {
  return StarToggleSwitch(
    value: true,
    onChanged: (_) {},
    label: 'Compact mode',
    description: 'Use a denser layout in the sidebar.',
  );
}
