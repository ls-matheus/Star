import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/friends/providers/friend_providers.dart';
import 'package:star_app/features/profile/presentation/sheets/change_nickname_sheet.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';

Future<void> showChangeFriendNicknameSheet(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String username,
  required String? currentNick,
}) async {
  final ChangeNicknameResult? result = await ChangeNicknameSheet.show(
    context,
    username: username,
    currentNick: currentNick,
  );
  if (result == null || !context.mounted) {
    return;
  }
  final StarLocalizations l10n = StarLocalizations.of(context);
  final toast = ref.read(toastProvider.notifier);
  try {
    await ref
        .read(friendRepositoryProvider)
        .updateNickname(userId: userId, nickname: result.nick);
    toast.show(
      StarToast(
        message: l10n.userProfileNicknameSuccess,
        variant: StarToastVariant.success,
      ),
    );
  } on Object catch (e) {
    if (context.mounted) {
      await showApiError(context, ApiErrorAction.generic, e);
    }
  }
}
