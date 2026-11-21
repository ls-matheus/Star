import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/providers/pickers/favorite_gifs_provider.dart';
import 'package:star_app/features/settings/providers/preferences/advanced_preferences_provider.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showFavoriteGifFirstTimePrompt({
  required BuildContext context,
  required Future<void> Function() onConfirm,
}) {
  if (isMobileLayout(context)) {
    return StarBottomSheet.show<void>(
      context,
      title: StarLocalizations.of(context).gifFavoriteFirstTimeTitle,
      useRootNavigator: true,
      builder: (BuildContext sheetContext, VoidCallback close) {
        return _FavoriteGifFirstTimePromptBody(
          onClose: close,
          onConfirm: onConfirm,
        );
      },
    );
  }

  return StarModal.show<void>(
    context,
    title: StarLocalizations.of(context).gifFavoriteFirstTimeTitle,
    centered: true,
    useRootNavigator: true,
    builder: (BuildContext dialogContext, VoidCallback close) {
      return _FavoriteGifFirstTimePromptBody(
        onClose: close,
        onConfirm: onConfirm,
      );
    },
    actionsBuilder: (void Function([void]) pop) => const <Widget>[],
  );
}

class _FavoriteGifFirstTimePromptBody extends ConsumerWidget {
  const _FavoriteGifFirstTimePromptBody({
    required this.onClose,
    required this.onConfirm,
  });

  final VoidCallback onClose;
  final Future<void> Function() onConfirm;

  Future<void> _chooseUrlOnly(WidgetRef ref) async {
    await ref
        .read(advancedPreferencesProvider.notifier)
        .setSaveGifFavoritesAsSavedMedia(value: false);
    ref.read(favoriteGifsProvider.notifier).markFirstTimePromptSeen();
    onClose();
    await onConfirm();
  }

  Future<void> _chooseSavedMedia(WidgetRef ref) async {
    await ref
        .read(advancedPreferencesProvider.notifier)
        .setSaveGifFavoritesAsSavedMedia(value: true);
    ref.read(favoriteGifsProvider.notifier).markFirstTimePromptSeen();
    onClose();
    await onConfirm();
  }

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final colors = context.colors;

    return StarBottomSheetContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.gifFavoriteFirstTimeDescription,
            style: context.textStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s3),
          Text(
            l10n.gifFavoriteFirstTimeUrlOnlyDetails,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s2),
          Text(
            l10n.gifFavoriteFirstTimeSavedMediaDetails,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s3),
          Text(
            l10n.gifFavoriteFirstTimeHint,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s4),
          StarButton.primary(
            label: l10n.gifFavoriteFirstTimeUseUrlOnly,
            onPressedAsync: () => _chooseUrlOnly(widgetRef),
          ),
          SizedBox(height: layout.s2),
          StarButton.secondary(
            label: l10n.gifFavoriteFirstTimeUseSavedMedia,
            onPressedAsync: () => _chooseSavedMedia(widgetRef),
          ),
        ],
      ),
    );
  }
}
