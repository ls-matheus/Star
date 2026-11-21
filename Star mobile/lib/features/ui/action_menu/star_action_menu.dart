import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart'
    show
        StarBottomSheet,
        StarBottomSheetGroupColumn,
        StarBottomSheetMenuItem,
        StarBottomSheetMenuRadioItem,
        StarBottomSheetSection,
        StarBottomSheetSubmenuItem,
        StarBottomSheetVariant,
        StarMenuGroup;
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/radio_group/star_radio_group.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

typedef StarActionMenuBuilder =
    List<Widget> Function(BuildContext context, VoidCallback close);

class StarActionMenu {
  StarActionMenu._();

  static Future<void> show(
    BuildContext context, {
    required Offset position,
    required StarActionMenuBuilder builder,
  }) {
    if (!usesDesktopPointerUi(context)) {
      return _showAsBottomSheet(context, builder: builder);
    }
    return _showAsOverlay(context, position: position, builder: builder);
  }

  static Future<void> _showAsBottomSheet(
    BuildContext context, {
    required StarActionMenuBuilder builder,
  }) async {
    await StarBottomSheet.show<void>(
      context,
      variant: StarBottomSheetVariant.menu,
      useRootNavigator: true,
      builder: (sheetContext, close) {
        final sections = _buildMobileSections(builder(sheetContext, close));

        return ListView(
          shrinkWrap: true,
          padding: StarBottomSheet.scrollViewPadding(sheetContext),
          children: [
            StarBottomSheetGroupColumn(
              children: [
                for (final section in sections)
                  StarBottomSheetSection(
                    title: section.title,
                    child: StarMenuGroup(children: section.items),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showAsOverlay(
    BuildContext context, {
    required Offset position,
    required StarActionMenuBuilder builder,
  }) {
    return pushStarDesktopMenu<void>(
      context,
      position: position,
      builder: (BuildContext menuContext, VoidCallback close) {
        return StarDesktopMenuPanel.fitContent(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: builder(menuContext, close),
            ),
          ),
        );
      },
    );
  }
}

class _StarMenuSectionData {
  final String? title;
  final List<Widget> items;

  const _StarMenuSectionData({required this.title, required this.items});
}

List<_StarMenuSectionData> _buildMobileSections(List<Widget> widgets) {
  final sections = <_StarMenuSectionData>[];
  final currentItems = <Widget>[];
  String? currentTitle;

  void flush() {
    if (currentItems.isEmpty) {
      return;
    }

    sections.add(
      _StarMenuSectionData(
        title: currentTitle,
        items: List<Widget>.from(currentItems),
      ),
    );
    currentItems.clear();
    currentTitle = null;
  }

  for (final widget in widgets) {
    switch (widget) {
      case StarMenuSectionHeader():
        flush();
        currentTitle = widget.label;
      case StarMenuDivider():
        flush();
      case StarMenuItem():
        currentItems.add(
          StarBottomSheetMenuItem(
            label: widget.label,
            hint: widget.hint,
            icon: widget.icon,
            iconColor: widget.iconColor,
            isDanger: widget.isDanger,
            enabled: widget.enabled,
            onTap: widget.onPressed,
          ),
        );
      case StarMenuRadioItem():
        currentItems.add(
          StarBottomSheetMenuRadioItem(
            label: widget.label,
            hint: widget.hint,
            isSelected: widget.isSelected,
            enabled: widget.enabled,
            onTap: widget.onPressed,
          ),
        );
      case StarMenuSubmenuItem():
        currentItems.add(
          StarBottomSheetSubmenuItem(
            label: widget.label,
            hint: widget.hint,
            onTap: widget.onPressed,
          ),
        );
    }
  }

  flush();

  return sections;
}

class StarMenuSectionHeader extends StatelessWidget {
  final String label;

  const StarMenuSectionHeader({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return StarDesktopMenuGroupLabel(label: label);
  }
}

class StarMenuItem extends StatelessWidget {
  const StarMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.trailingIcon,
    this.hint,
    this.enabled = true,
    this.isDanger = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final PhosphorIconData? icon;
  final PhosphorIconData? trailingIcon;
  final Color? iconColor;
  final String? hint;
  final bool enabled;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color foreground = !enabled
        ? colors.interactiveMuted
        : isDanger
        ? starDesktopMenuDangerText(colors)
        : colors.textPrimary;
    final Color iconForeground = iconColor ?? foreground;
    final Widget? iconWidget = icon == null
        ? null
        : PhosphorIcon(
            icon!,
            size: kStarDesktopMenuIconSize,
            color: iconForeground,
          );
    final Widget? trailingIconWidget = trailingIcon == null
        ? null
        : PhosphorIcon(
            trailingIcon!,
            size: kStarDesktopMenuIconSize,
            color: iconForeground,
          );
    return StarDesktopMenuRow(
      label: label,
      hint: hint,
      onTap: onPressed,
      enabled: enabled,
      isDanger: isDanger,
      leading: trailingIconWidget == null ? null : iconWidget,
      trailing: trailingIconWidget ?? iconWidget,
    );
  }
}

class StarMenuRadioItem extends StatelessWidget {
  const StarMenuRadioItem({
    required this.label,
    required this.onPressed,
    required this.isSelected,
    this.hint,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isSelected;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return StarDesktopMenuRow(
      label: label,
      hint: hint,
      onTap: onPressed,
      enabled: enabled,
      selected: isSelected,
      trailing: StarRadioIndicator(selected: isSelected),
    );
  }
}

class StarMenuCheckboxItem extends StatelessWidget {
  const StarMenuCheckboxItem({
    required this.label,
    required this.onPressed,
    required this.isChecked,
    this.hint,
    this.enabled = true,
    this.isDanger = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isChecked;
  final String? hint;
  final bool enabled;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return StarDesktopMenuRow(
      label: label,
      hint: hint,
      onTap: onPressed,
      enabled: enabled,
      isDanger: isDanger,
      checked: isChecked,
      trailingBuilder: (BuildContext context, {required bool highlighted}) =>
          StarDesktopMenuCheckbox(
            isChecked: isChecked,
            dangerHighlighted: isDanger && highlighted,
          ),
    );
  }
}

class StarMenuSubmenuItem extends StatelessWidget {
  const StarMenuSubmenuItem({
    required this.label,
    required this.onPressed,
    this.hint,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return StarDesktopMenuRow(
      label: label,
      hint: hint,
      onTap: onPressed,
      trailing: PhosphorIcon(
        PhosphorIconsBold.caretRight,
        size: kStarDesktopMenuCaretSize,
        color: context.colors.textTertiary,
      ),
    );
  }
}

class StarMenuDivider extends StatelessWidget {
  const StarMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const StarDesktopMenuSeparator();
  }
}

@StarWidgetPreview(name: 'Section header', group: 'StarActionMenu')
Widget starMenuSectionHeaderPreview() {
  return const StarMenuSectionHeader(label: 'Message actions');
}

@StarWidgetPreview(name: 'Menu item', group: 'StarActionMenu')
Widget starMenuItemPreview() {
  return StarMenuItem(
    label: 'Copy text',
    hint: 'Copy the selected message',
    icon: PhosphorIconsBold.copy,
    onPressed: () {},
  );
}

@StarWidgetPreview(name: 'Danger item', group: 'StarActionMenu')
Widget starMenuItemDangerPreview() {
  return StarMenuItem(
    label: 'Delete message',
    icon: PhosphorIconsBold.trash,
    isDanger: true,
    onPressed: () {},
  );
}

@StarWidgetPreview(name: 'Divider', group: 'StarActionMenu')
Widget starMenuDividerPreview() {
  return const StarMenuDivider();
}
