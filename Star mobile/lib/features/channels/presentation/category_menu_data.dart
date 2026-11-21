import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/action_menu/star_action_menu.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

enum CategoryMenuAction {
  markAsRead,
  toggleCollapse,
  toggleCollapseAll,
  mute,
  createChannel,
  editCategory,
  deleteCategory,
  copyCategoryId,
  debugCategory,
  resetMatureContentAgree,
}

class CategoryMenuEntry {
  const CategoryMenuEntry({
    required this.label,
    required this.action,
    this.icon,
    this.isDanger = false,
    this.hint,
    this.enabled = true,
  });

  final String label;
  final CategoryMenuAction action;
  final PhosphorIconData? icon;
  final bool isDanger;
  final String? hint;
  final bool enabled;
}

typedef CategoryMenuGroup = List<CategoryMenuEntry>;

class CategoryMenuState {
  const CategoryMenuState({
    required this.hasUnread,
    required this.isCollapsed,
    required this.allCategoriesCollapsed,
    required this.isMuted,
    required this.canManageChannels,
    required this.developerMode,
    required this.hasAgreedToMatureContent,
    this.mutedHint,
  });

  final bool hasUnread;
  final bool isCollapsed;
  final bool allCategoriesCollapsed;
  final bool isMuted;
  final bool canManageChannels;
  final bool developerMode;
  final bool hasAgreedToMatureContent;
  final String? mutedHint;
}

CategoryMenuState resolveCategoryMenuState({
  required bool hasUnread,
  required bool isCollapsed,
  required bool allCategoriesCollapsed,
  required bool isMuted,
  required bool canManageChannels,
  required bool developerMode,
  required bool hasAgreedToMatureContent,
  String? mutedHint,
}) {
  return CategoryMenuState(
    hasUnread: hasUnread,
    isCollapsed: isCollapsed,
    allCategoriesCollapsed: allCategoriesCollapsed,
    isMuted: isMuted,
    canManageChannels: canManageChannels,
    developerMode: developerMode,
    hasAgreedToMatureContent: hasAgreedToMatureContent,
    mutedHint: mutedHint,
  );
}

List<CategoryMenuGroup> buildCategoryMenuGroups({
  required StarLocalizations l10n,
  required CategoryMenuState state,
}) {
  final List<CategoryMenuEntry> manageItems = <CategoryMenuEntry>[
    if (state.canManageChannels)
      CategoryMenuEntry(
        label: l10n.guildNavbarCreateChannel,
        icon: PhosphorIconsFill.plusCircle,
        action: CategoryMenuAction.createChannel,
      ),
    if (state.canManageChannels)
      CategoryMenuEntry(
        label: l10n.channelSettingsEditCategory,
        icon: PhosphorIconsFill.pencilSimple,
        action: CategoryMenuAction.editCategory,
      ),
    if (state.canManageChannels)
      CategoryMenuEntry(
        label: l10n.channelSettingsDeleteCategory,
        icon: PhosphorIconsFill.trash,
        isDanger: true,
        action: CategoryMenuAction.deleteCategory,
      ),
  ];
  final List<CategoryMenuEntry> utilityItems = <CategoryMenuEntry>[
    if (state.developerMode)
      CategoryMenuEntry(
        label: l10n.dmDebugCategory,
        icon: PhosphorIconsFill.bugBeetle,
        action: CategoryMenuAction.debugCategory,
      ),
    if (state.developerMode && state.hasAgreedToMatureContent)
      CategoryMenuEntry(
        label: l10n.channelMenuResetMatureContentAgreeState,
        icon: PhosphorIconsFill.bugBeetle,
        action: CategoryMenuAction.resetMatureContentAgree,
      ),
    CategoryMenuEntry(
      label: l10n.categoryCopyCategoryId,
      icon: PhosphorIconsFill.copy,
      action: CategoryMenuAction.copyCategoryId,
    ),
  ];
  return <CategoryMenuGroup>[
    <CategoryMenuEntry>[
      CategoryMenuEntry(
        label: l10n.dmMarkAsRead,
        icon: PhosphorIconsFill.envelopeOpen,
        action: CategoryMenuAction.markAsRead,
        enabled: state.hasUnread,
      ),
    ],
    <CategoryMenuEntry>[
      CategoryMenuEntry(
        label: state.isCollapsed
            ? l10n.categoryExpandCategory
            : l10n.categoryCollapseCategory,
        icon: state.isCollapsed
            ? PhosphorIconsBold.caretRight
            : PhosphorIconsBold.caretDown,
        action: CategoryMenuAction.toggleCollapse,
      ),
      CategoryMenuEntry(
        label: state.allCategoriesCollapsed
            ? l10n.categoryExpandAllCategories
            : l10n.categoryCollapseAllCategories,
        icon: state.allCategoriesCollapsed
            ? PhosphorIconsBold.caretRight
            : PhosphorIconsBold.caretDown,
        action: CategoryMenuAction.toggleCollapseAll,
      ),
    ],
    <CategoryMenuEntry>[
      CategoryMenuEntry(
        label: state.isMuted
            ? l10n.categoryUnmuteCategory
            : l10n.categoryMuteCategory,
        icon: state.isMuted
            ? PhosphorIconsFill.bell
            : PhosphorIconsFill.bellSlash,
        hint: state.mutedHint,
        action: CategoryMenuAction.mute,
      ),
    ],
    if (manageItems.isNotEmpty) manageItems,
    utilityItems,
  ];
}

Widget categoryMenuGroupsToBottomSheetContent({
  required BuildContext context,
  required ScrollController scrollController,
  required List<CategoryMenuGroup> groups,
  required CategoryMenuState menuState,
  required void Function(CategoryMenuAction action) onAction,
}) {
  final layout = context.layout;
  final List<Widget> menuGroups = <Widget>[
    for (final CategoryMenuGroup group in groups)
      StarMenuGroup(
        children: [
          for (final CategoryMenuEntry entry in group)
            _categoryMenuBottomSheetItem(
              context: context,
              entry: entry,
              menuState: menuState,
              onAction: onAction,
            ),
        ],
      ),
  ];
  return ListView(
    controller: scrollController,
    padding: StarBottomSheet.scrollViewPadding(
      context,
      padding: EdgeInsets.symmetric(horizontal: layout.s4),
    ),
    children: [StarBottomSheetGroupColumn(children: menuGroups)],
  );
}

StarBottomSheetMenuItem _categoryMenuBottomSheetItem({
  required BuildContext context,
  required CategoryMenuEntry entry,
  required CategoryMenuState menuState,
  required void Function(CategoryMenuAction action) onAction,
}) {
  return StarBottomSheetMenuItem(
    label: entry.label,
    hint: entry.hint,
    icon: entry.icon,
    enabled: entry.enabled,
    isDanger: entry.isDanger,
    onTap: () => onAction(entry.action),
  );
}

List<Widget> categoryMenuGroupsToWidgets({
  required BuildContext context,
  required List<CategoryMenuGroup> groups,
  required CategoryMenuState menuState,
  required void Function(CategoryMenuAction action) onAction,
}) {
  final List<Widget> widgets = <Widget>[];
  for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
    if (groupIndex > 0) {
      widgets.add(const StarMenuDivider());
    }
    for (final CategoryMenuEntry entry in groups[groupIndex]) {
      widgets.add(
        StarMenuItem(
          label: entry.label,
          icon: entry.icon,
          hint: entry.hint,
          enabled: entry.enabled,
          isDanger: entry.isDanger,
          onPressed: () => onAction(entry.action),
        ),
      );
    }
  }
  return widgets;
}
