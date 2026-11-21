import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/chat/providers/core/chat_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

Future<void> confirmAndDeleteMyMessagesInChannel(
  BuildContext context,
  WidgetRef ref, {
  required String channelId,
  required bool isPrivateConversation,
}) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final String title = isPrivateConversation
      ? l10n.dmDeleteMyMessagesTitle
      : l10n.channelMenuDeleteMyMessagesTitle;
  final String description = isPrivateConversation
      ? l10n.dmDeleteMyMessagesDescription
      : l10n.channelMenuDeleteMyMessagesDescription;
  final bool? confirmed = await StarConfirmModal.show(
    context,
    title: title,
    description: description,
    confirmLabel: l10n.channelMenuDeleteMyMessagesConfirm,
    isDanger: true,
    onConfirm: () {},
  );
  if (confirmed != true) {
    return;
  }
  final toast = ref.read(toastProvider.notifier);
  try {
    await ref
        .read(starClientProvider)
        .channels
        .bulkDeleteMyMessagesInChannel(
          channelId: channelId,
          body: const SudoVerificationSchema(),
        );
    if (ref.read(chatViewModelProvider).channelId == channelId) {
      await ref.read(chatViewModelProvider.notifier).reloadCurrentChannel();
    }
    toast.show(
      StarToast(
        message: l10n.channelMenuDeletedYourMessages,
        variant: StarToastVariant.success,
      ),
    );
  } on Object {
    toast.show(
      StarToast(
        message: l10n.channelMenuCouldNotDeleteYourMessages,
        variant: StarToastVariant.danger,
      ),
    );
  }
}
