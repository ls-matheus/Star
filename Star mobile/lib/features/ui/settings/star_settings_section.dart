import 'package:star_app/core/deep_links/user_settings_deep_link.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/utils/user_settings/user_settings_deep_link_scope.dart';
import 'package:star_app/features/settings/utils/user_settings/user_settings_section_scroll.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart'
    show isMobileLayout;
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/settings/star_settings_configure_row.dart';
import 'package:star_app/features/ui/settings/star_settings_heading_link_button.dart';
import 'package:star_app/features/ui/switch_group/star_switch_group.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

enum StarSettingsSectionDensity { comfortable, compact }

class StarSettingsSection extends StatelessWidget {
  const StarSettingsSection({
    required this.title,
    required this.children,
    super.key,
    this.description,
    this.isFirst = false,
    this.density = StarSettingsSectionDensity.comfortable,
    this.sectionId,
    this.titleTrailing,
    this.linkable = true,
  });

  final String title;
  final String? description;
  final bool isFirst;
  final List<Widget> children;
  final StarSettingsSectionDensity density;
  final String? sectionId;
  final Widget? titleTrailing;
  final bool linkable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    final childGap = switch (density) {
      StarSettingsSectionDensity.comfortable => layout.s8,
      StarSettingsSectionDensity.compact => layout.s2,
    };

    final UserSettingsDeepLinkScope? linkScope =
        UserSettingsDeepLinkScope.maybeOf(context);
    final String? sectionLinkHref = sectionId == null || linkScope == null
        ? null
        : userSettingsSectionDeepLinkHref(
            sectionId: sectionId!,
            tab: linkScope.settingsTab,
            isTouchPrimary: linkScope.isTouchPrimary,
            pageSection: linkScope.pageSection,
            linkable: linkable,
          );
    final Widget? sectionLinkButton = sectionLinkHref == null
        ? null
        : StarSettingsHeadingLinkButton(href: sectionLinkHref);
    final Widget? headerTrailing = switch ((sectionLinkButton, titleTrailing)) {
      (null, null) => null,
      (final Widget link, null) => link,
      (null, final Widget trailing) => trailing,
      (final Widget link, final Widget trailing) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          link,
          SizedBox(width: layout.s1),
          trailing,
        ],
      ),
    };

    final Key? scrollKey = sectionId == null
        ? null
        : UserSettingsSectionScrollKeys.keyFor(sectionId!);

    if (isMobileLayout(context)) {
      final List<Widget> grouped = groupSettingsMenuRows(children);
      return KeyedSubtree(
        key: scrollKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            StarSettingsGroupLabel(
              title: title,
              description: description,
              trailing: headerTrailing,
            ),
            SizedBox(height: layout.s2),
            for (int i = 0; i < grouped.length; i++) ...[
              grouped[i],
              if (i < grouped.length - 1) SizedBox(height: layout.s4),
            ],
            SizedBox(height: layout.s6),
          ],
        ),
      );
    }

    if (usesDesktopPointerUi(context)) {
      final double desktopChildGap = switch (density) {
        StarSettingsSectionDensity.comfortable => 20,
        StarSettingsSectionDensity.compact => layout.s2,
      };
      return KeyedSubtree(
        key: scrollKey,
        child: Container(
          padding: EdgeInsets.only(top: isFirst ? 0 : 24, bottom: 24),
          decoration: isFirst
              ? null
              : BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colors.backgroundModifierAccent),
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: textStyles.heading.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          if (sectionLinkButton != null) ...[
                            const SizedBox(width: 8),
                            sectionLinkButton,
                          ],
                        ],
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 8),
                      titleTrailing!,
                    ],
                  ],
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: textStyles.bodySmall.copyWith(
                    fontSize: 14,
                    height: 1.35,
                    color: colors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: desktopChildGap),
              ],
            ],
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: scrollKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isFirst) ...[
            Divider(color: colors.borderColor),
            SizedBox(height: layout.s8),
          ],
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: textStyles.heading.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              ?headerTrailing,
            ],
          ),
          if (description != null) ...[
            SizedBox(height: layout.s1),
            Text(
              description!,
              style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
          SizedBox(height: layout.s4),
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: childGap),
          ],
          SizedBox(height: layout.s8),
        ],
      ),
    );
  }
}

class StarSettingsGroupLabel extends StatelessWidget {
  const StarSettingsGroupLabel({
    required this.title,
    this.description,
    this.trailing,
    super.key,
  });

  final String title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: context.textStyles.categoryName),
              ),
            ),
            ?trailing,
          ],
        ),
        if (description != null)
          Padding(
            padding: EdgeInsets.only(top: layout.s1),
            child: Text(
              description!,
              style: context.textStyles.timestamp.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

List<Widget> groupSettingsMenuRows(List<Widget> children) {
  final List<Widget> result = <Widget>[];
  List<Widget> run = <Widget>[];
  void flush() {
    if (run.isNotEmpty) {
      result.add(StarMenuGroup(children: run));
      run = <Widget>[];
    }
  }

  for (final Widget child in children) {
    if (_isSettingsMenuRow(child)) {
      run.add(child);
    } else {
      flush();
      result.add(child);
    }
  }
  flush();
  return result;
}

bool _isSettingsMenuRow(Widget widget) =>
    widget is StarSettingsSwitchItem ||
    widget is StarSettingsConfigureRow ||
    widget is StarSettingsAccessoryRow ||
    widget is StarSwitchGroupItem ||
    widget is StarBottomSheetMenuItem ||
    widget is StarBottomSheetSubmenuItem;

@StarWidgetPreview(name: 'Default', group: 'StarSettingsSection')
Widget starSettingsSectionPreview() {
  return const StarSettingsSection(
    title: 'Connections',
    description: 'Control who can send you friend requests and direct messages',
    isFirst: true,
    children: [Text('Subsection content goes here')],
  );
}

@StarWidgetPreview(name: 'Compact', group: 'StarSettingsSection')
Widget starSettingsSectionCompactPreview() {
  return const StarSettingsSection(
    title: 'Blocked Users',
    description:
        "Blocked users can't send you friend requests or message you "
        'directly.',
    isFirst: true,
    density: StarSettingsSectionDensity.compact,
    children: [Text('Row 1'), Text('Row 2'), Text('Row 3')],
  );
}
