import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/favorites/presentation/sheets/create_favorite_category_sheet.dart';
import 'package:star_app/features/favorites/providers/favorite_channels_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

Future<void> showFavoritesCategoryMenu(
  BuildContext context,
  WidgetRef ref, {
  required String categoryId,
  required String categoryName,
  required bool isCollapsed,
  required VoidCallback onToggleCollapsed,
  required Offset position,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);

  return StarActionMenu.show(
    context,
    position: position,
    builder: (menuContext, close) => [
      StarMenuItem(
        label: l10n.favoritesRenameCategory,
        icon: PhosphorIconsBold.pencilSimple,
        onPressed: () {
          close();
          unawaited(
            showRenameFavoriteCategorySheet(
              context,
              categoryId: categoryId,
              currentName: categoryName,
            ),
          );
        },
      ),
      StarMenuItem(
        label: isCollapsed
            ? l10n.categoryExpandCategory
            : l10n.categoryCollapseCategory,
        icon: isCollapsed
            ? PhosphorIconsBold.caretDown
            : PhosphorIconsBold.caretRight,
        onPressed: () {
          close();
          onToggleCollapsed();
        },
      ),
      StarMenuItem(
        label: l10n.channelSettingsDeleteCategory,
        icon: PhosphorIconsFill.trash,
        isDanger: true,
        onPressed: () async {
          await ref
              .read(favoriteChannelsRepositoryProvider)
              .removeCategory(categoryId);
          close();
        },
      ),
    ],
  );
}
