import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/favorites/domain/favorite_category_id.dart';
import 'package:star_app/features/favorites/providers/favorite_channels_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showCreateFavoriteCategorySheet(BuildContext context) async {
  final l10n = StarLocalizations.of(context);
  final controller = TextEditingController();
  await StarBottomSheet.show<void>(
    context,
    title: l10n.favoritesCreateCategory,
    builder: (sheetContext, close) => Consumer(
      builder: (context, ref, _) {
        return StarBottomSheetContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StarInput(
                controller: controller,
                label: l10n.favoritesCategoryNameLabel,
              ),
              const SizedBox(height: 16),
              StarButton.primary(
                label: l10n.favoritesCreateCategory,
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    return;
                  }
                  await ref
                      .read(favoriteChannelsRepositoryProvider)
                      .addCategory(
                        id: generateFavoriteCategoryId(),
                        name: name,
                      );
                  close();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> showRenameFavoriteCategorySheet(
  BuildContext context, {
  required String categoryId,
  required String currentName,
}) async {
  final l10n = StarLocalizations.of(context);
  final controller = TextEditingController(text: currentName);
  await StarBottomSheet.show<void>(
    context,
    title: l10n.favoritesRenameCategory,
    builder: (sheetContext, close) => Consumer(
      builder: (context, ref, _) {
        return StarBottomSheetContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StarInput(
                controller: controller,
                label: l10n.favoritesCategoryNameLabel,
              ),
              const SizedBox(height: 16),
              StarButton.primary(
                label: l10n.save,
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    return;
                  }
                  await ref
                      .read(favoriteChannelsRepositoryProvider)
                      .renameCategory(id: categoryId, name: name);
                  close();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
