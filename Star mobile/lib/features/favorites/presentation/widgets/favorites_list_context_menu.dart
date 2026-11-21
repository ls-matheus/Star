import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/favorites/presentation/sheets/create_favorite_category_sheet.dart';
import 'package:star_app/features/favorites/providers/favorite_channels_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

Future<void> showFavoritesListMenu(
  BuildContext context,
  WidgetRef ref, {
  required Offset position,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final bool hideMuted =
      ref.read(favoriteSettingsProvider).value?.hideMuted ?? false;

  return StarActionMenu.show(
    context,
    position: position,
    builder: (menuContext, close) => [
      StarMenuItem(
        label: l10n.favoritesCreateCategory,
        icon: PhosphorIconsBold.folderPlus,
        onPressed: () {
          close();
          unawaited(showCreateFavoriteCategorySheet(context));
        },
      ),
      StarMenuItem(
        label: hideMuted
            ? l10n.favoritesShowMutedChannels
            : l10n.favoritesHideMutedChannels,
        icon: PhosphorIconsBold.eyeSlash,
        onPressed: () async {
          await ref
              .read(favoriteChannelsRepositoryProvider)
              .setHideMuted(value: !hideMuted);
          close();
        },
      ),
    ],
  );
}
