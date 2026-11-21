import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/limits/instance_limit_provider.dart';
import 'package:star_app/core/limits/limit_key.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/bookmarks/data/saved_messages_repository.dart';
import 'package:star_app/features/bookmarks/providers/saved_messages_provider.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';

Future<void> toggleSavedMessageBookmark({
  required WidgetRef ref,
  required StarLocalizations l10n,
  required String channelId,
  required String messageId,
}) async {
  final SavedMessagesRepository repository = ref.read(
    savedMessagesRepositoryProvider,
  );
  if (await ref
      .read(starDatabaseProvider)
      .savedMessageDao
      .isSaved(messageId)) {
    await unsaveMessageBookmark(ref: ref, l10n: l10n, messageId: messageId);
    return;
  }
  try {
    await repository.saveMessage(channelId: channelId, messageId: messageId);
  } on Object catch (error) {
    await _showBookmarkError(ref, error);
    return;
  }
  _showBookmarkToast(ref, l10n, added: true);
}

Future<void> unsaveMessageBookmark({
  required WidgetRef ref,
  required StarLocalizations l10n,
  required String messageId,
}) async {
  ref.read(savedMessagesProvider.notifier).handleMessageDelete(messageId);
  try {
    await ref.read(savedMessagesRepositoryProvider).unsaveMessage(messageId);
  } on Object catch (error) {
    await _showBookmarkError(ref, error);
    return;
  }
  _showBookmarkToast(ref, l10n, added: false);
}

Future<void> _showBookmarkError(WidgetRef ref, Object error) {
  return showApiErrorFromRoot(
    ApiErrorAction.saveBookmark,
    error,
    details: ApiErrorDetails(
      count: ref.read(instanceLimitProvider(LimitKeys.maxBookmarks)),
    ),
  );
}

void _showBookmarkToast(
  WidgetRef ref,
  StarLocalizations l10n, {
  required bool added,
}) {
  ref
      .read(toastProvider.notifier)
      .show(
        StarToast(
          message: added
              ? l10n.savedMessagesAddedToast
              : l10n.savedMessagesRemovedToast,
          variant: StarToastVariant.success,
        ),
      );
}
