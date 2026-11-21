import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/settings/star_settings_section.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class StarSettingsNavItem {
  const StarSettingsNavItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
    this.hint,
    this.isDanger = false,
  }) : assert(icon != null || leading != null, 'Provide icon or leading');

  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback onTap;
  final bool isDanger;
}

class StarSettingsNavGroup {
  const StarSettingsNavGroup({required this.items, this.label});

  final String? label;
  final List<StarSettingsNavItem> items;
}

class StarSettingsNavList extends StatelessWidget {
  const StarSettingsNavList({
    required this.groups,
    super.key,
    this.controller,
    this.header,
    this.profileSection,
    this.empty,
    this.footer,
    this.padding,
  });

  final List<StarSettingsNavGroup> groups;
  final ScrollController? controller;
  final Widget? header;
  final Widget? profileSection;
  final Widget? empty;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final int headerCount = header == null ? 0 : 1;
    final int profileCount = profileSection == null ? 0 : 1;
    final int emptyCount = empty != null && groups.isEmpty ? 1 : 0;
    final int footerCount = footer == null ? 0 : 1;

    return ListView.builder(
      controller: controller,
      padding: StarBottomSheet.scrollViewPadding(
        context,
        padding: padding ?? EdgeInsets.symmetric(horizontal: layout.pageGutter),
      ),
      itemCount:
          headerCount + profileCount + groups.length + emptyCount + footerCount,
      itemBuilder: (context, index) {
        var remaining = index;
        if (header != null) {
          if (remaining == 0) {
            return header!;
          }
          remaining--;
        }
        if (profileSection != null) {
          if (remaining == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: layout.s4),
              child: StarMenuGroup(children: [profileSection!]),
            );
          }
          remaining--;
        }
        if (remaining < groups.length) {
          return _StarSettingsNavGroupWidget(group: groups[remaining]);
        }
        remaining -= groups.length;
        if (emptyCount == 1) {
          if (remaining == 0) {
            return empty!;
          }
          remaining--;
        }
        return footer!;
      },
    );
  }
}

class _StarSettingsNavGroupWidget extends StatelessWidget {
  const _StarSettingsNavGroupWidget({required this.group});

  final StarSettingsNavGroup group;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return Padding(
      padding: EdgeInsets.only(bottom: layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.label case final String label) ...[
            StarSettingsGroupLabel(title: label),
            SizedBox(height: layout.s2),
          ],
          StarMenuGroup(
            children: [
              for (final item in group.items)
                _StarSettingsNavItemWidget(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarSettingsNavItemWidget extends StatelessWidget {
  const _StarSettingsNavItemWidget({required this.item});

  final StarSettingsNavItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isDanger) {
      return StarBottomSheetMenuItem(
        label: item.label,
        onTap: item.onTap,
        icon: item.icon,
        leading: item.leading,
        isDanger: true,
      );
    }

    return StarBottomSheetSubmenuItem(
      label: item.label,
      hint: item.hint,
      onTap: item.onTap,
      icon: item.icon,
      leading: item.leading,
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarSettingsNavList')
Widget starSettingsNavListPreview() {
  return SizedBox(
    height: 220,
    child: StarSettingsNavList(
      groups: [
        StarSettingsNavGroup(
          label: 'User settings',
          items: [
            StarSettingsNavItem(
              label: 'My account',
              icon: PhosphorIconsBold.user,
              onTap: () {},
            ),
            StarSettingsNavItem(
              label: 'Log out',
              icon: PhosphorIconsBold.signOut,
              onTap: () {},
              isDanger: true,
            ),
          ],
        ),
      ],
    ),
  );
}
