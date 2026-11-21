import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/favorites/providers/favorite_channels_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showSetFavoriteNicknameSheet(
  BuildContext context, {
  required String channelId,
  String? currentNickname,
}) async {
  final l10n = StarLocalizations.of(context);
  final controller = TextEditingController(text: currentNickname ?? '');
  await StarBottomSheet.show<void>(
    context,
    title: l10n.favoritesSetNickname,
    builder: (sheetContext, close) => Consumer(
      builder: (context, ref, _) {
        return StarBottomSheetContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StarInput(
                controller: controller,
                label: l10n.favoritesNicknameLabel,
              ),
              const SizedBox(height: 16),
              StarButton.primary(
                label: l10n.favoritesSaveNickname,
                onPressed: () async {
                  final nickname = controller.text.trim();
                  await ref
                      .read(favoriteChannelsRepositoryProvider)
                      .setChannelNickname(
                        channelId: channelId,
                        nickname: nickname.isEmpty ? null : nickname,
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
