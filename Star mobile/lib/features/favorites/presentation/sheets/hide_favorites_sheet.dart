import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showHideFavoritesSheet(
  BuildContext context, {
  required VoidCallback onConfirmed,
}) async {
  final l10n = StarLocalizations.of(context);
  await StarBottomSheet.show<void>(
    context,
    title: l10n.favoritesHideConfirmTitle,
    builder: (sheetContext, close) => Consumer(
      builder: (context, ref, _) {
        return StarBottomSheetContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.favoritesHideConfirmDescription),
              const SizedBox(height: 16),
              StarButton.dangerPrimary(
                label: l10n.favoritesHideConfirmTitle,
                onPressed: () async {
                  await ref
                      .read(appearancePreferencesProvider.notifier)
                      .setShowFavorites(value: false);
                  close();
                  onConfirmed();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
