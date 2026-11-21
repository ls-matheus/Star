import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart'
    show isMobileLayout;
import 'package:star_app/features/ui/badge/star_settings_status_badge.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/features/ui/toggle_switch/star_switch_control.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_app/shared/utils/star_haptics.dart';

class StarSwitchGroup extends StatelessWidget {
  const StarSwitchGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => StarMenuGroup(children: children);
}

class StarSwitchGroupItem extends StatelessWidget {
  const StarSwitchGroupItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.labelBadge,
    super.key,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final Widget? labelBadge;

  @override
  Widget build(BuildContext context) => StarBottomSheetMenuItem(
    label: label,
    labelBadge: labelBadge,
    hint: description,
    enabled: enabled,
    toggled: value,
    onTap: () {
      StarHaptics.selection();
      onChanged(!value);
    },
    trailing: StarSwitchControl(value: value, enabled: enabled),
  );
}

class StarSettingsSwitchGroup extends StatelessWidget {
  const StarSettingsSwitchGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    if (isMobileLayout(context)) {
      return StarMenuGroup(children: children);
    }

    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class StarSettingsSwitchItem extends StatelessWidget {
  const StarSettingsSwitchItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.labelBadge,
    super.key,
  }) : grouped = false;

  const StarSettingsSwitchItem.grouped({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.labelBadge,
    super.key,
  }) : grouped = true;

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool grouped;
  final Widget? labelBadge;

  @override
  Widget build(BuildContext context) {
    if (isMobileLayout(context)) {
      return StarMenuGroup.ensureGrouped(
        context,
        StarSwitchGroupItem(
          label: label,
          description: description,
          value: value,
          onChanged: onChanged,
          enabled: enabled,
          labelBadge: labelBadge,
        ),
      );
    }
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final bool desktop = usesDesktopPointerUi(context);
    final minHeight = desktop
        ? 44.0
        : grouped
        ? layout.settingsSwitchGroupedRowMinHeight
        : layout.settingsSwitchRowMinHeight;

    return StarTappable(
      enabled: enabled,
      minSize: Size(layout.touchTargetMin, minHeight),
      onTap: () {
        StarHaptics.selection();
        onChanged(!value);
      },
      semanticLabel: description != null ? '$label. $description' : label,
      toggled: value,
      excludeChildSemantics: true,
      builder: (context, states) {
        final isPressed = states.contains(WidgetState.pressed);

        return AnimatedContainer(
          duration: context.motion.fast,
          curve: context.motion.curve,
          color: isPressed && !desktop
              ? colors.backgroundModifierHover.withValues(alpha: 0.45)
              : Colors.transparent,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: EdgeInsets.symmetric(vertical: layout.s1),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StarLabelWithBadge(
                      badge: labelBadge,
                      label: Text(
                        label,
                        style: textStyles.bodySmall.copyWith(
                          color: enabled || desktop
                              ? colors.textPrimary
                              : colors.textTertiary,
                          fontWeight: FontWeight.w500,
                          height: desktop ? 20 / 14 : 1.4,
                        ),
                      ),
                    ),
                    if (description != null) ...[
                      SizedBox(height: layout.s1),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: desktop ? 16 : 0,
                        ),
                        child: Text(
                          description!,
                          style: textStyles.bodySmall.copyWith(
                            color: colors.textPrimaryMuted,
                            height: desktop ? 20 / 14 : 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: layout.s4),
              StarSwitchControl(value: value, enabled: enabled),
            ],
          ),
        );
      },
    );
  }
}

class StarSettingsAccessoryRow extends StatelessWidget {
  const StarSettingsAccessoryRow({
    required this.label,
    required this.trailing,
    required this.onTap,
    this.description,
    super.key,
  });

  final String label;
  final String? description;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isMobileLayout(context)) {
      return StarMenuGroup.ensureGrouped(
        context,
        StarBottomSheetMenuItem(
          label: label,
          hint: description,
          onTap: onTap,
          trailing: trailing,
        ),
      );
    }
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final minHeight = layout.settingsSwitchRowMinHeight;

    return SizedBox(
      width: double.infinity,
      child: StarTappable(
        minSize: Size(layout.touchTargetMin, minHeight),
        onTap: onTap,
        semanticLabel: description != null ? '$label. $description' : label,
        excludeChildSemantics: true,
        builder: (context, states) {
          final isPressed = states.contains(WidgetState.pressed);

          return AnimatedContainer(
            duration: context.motion.fast,
            curve: context.motion.curve,
            color: isPressed
                ? colors.backgroundModifierHover.withValues(alpha: 0.45)
                : Colors.transparent,
            constraints: BoxConstraints(minHeight: minHeight),
            padding: EdgeInsets.symmetric(vertical: layout.s1),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      if (description != null) ...[
                        SizedBox(height: layout.s1),
                        Text(
                          description!,
                          style: textStyles.bodySmall.copyWith(
                            color: colors.textPrimaryMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: layout.s4),
                trailing,
              ],
            ),
          );
        },
      ),
    );
  }
}

@StarWidgetPreview(name: 'Group', group: 'StarSwitchGroup')
Widget starSwitchGroupPreview() {
  return StarSwitchGroup(
    children: [
      StarSwitchGroupItem(
        label: 'Message previews',
        description: 'Show a short excerpt under muted channels.',
        value: true,
        onChanged: (_) {},
      ),
      StarSwitchGroupItem(
        label: 'Link embeds',
        value: false,
        onChanged: (_) {},
      ),
    ],
  );
}
