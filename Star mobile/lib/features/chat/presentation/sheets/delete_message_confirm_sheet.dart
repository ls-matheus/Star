import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_confirm_preview.dart';
import 'package:star_app/features/chat/providers/core/chat_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_confirm_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

BuildContext? _deleteConfirmSheetContext(BuildContext? fallback) {
  final BuildContext? root = rootNavigatorKey.currentContext;
  if (root != null && root.mounted) {
    return root;
  }
  if (fallback != null && fallback.mounted) {
    return fallback;
  }
  return null;
}

Future<bool?> showDeleteMessageConfirmSheet(
  BuildContext? context,
  WidgetRef ref, {
  required Message message,
  String? guildId,
}) async {
  final BuildContext? sheetContext = _deleteConfirmSheetContext(context);
  if (sheetContext == null) {
    return null;
  }
  final l10n = StarLocalizations.of(sheetContext);
  final String messageId = message.id;
  final bool? confirmed = await StarConfirmSheet.show(
    sheetContext,
    title: l10n.chatMessageDeleteConfirmTitle,
    description: message.isCrossposted
        ? l10n.chatMessageDeletePublished
        : l10n.chatMessageDeleteConfirmDescription,
    body: MessageConfirmPreview(message: message, guildId: guildId),
    confirmLabel: l10n.chatMessageDelete,
    isDanger: true,
  );
  if (confirmed ?? false) {
    unawaited(
      ref.read(chatViewModelProvider.notifier).deleteMessage(messageId),
    );
  }
  return confirmed;
}

Future<bool?> showDeleteAttachmentConfirmSheet(
  BuildContext? context,
  WidgetRef ref, {
  required String messageId,
  required Attachment attachment,
}) async {
  final BuildContext? sheetContext = _deleteConfirmSheetContext(context);
  if (sheetContext == null) {
    return null;
  }
  final l10n = StarLocalizations.of(sheetContext);
  final bool? confirmed = await StarConfirmSheet.show(
    sheetContext,
    title: l10n.chatMessageDeleteAttachment,
    description: l10n.chatMessageDeleteAttachmentConfirmDescription,
    confirmLabel: l10n.chatMessageDeleteAttachment,
    isDanger: true,
  );
  if (confirmed ?? false) {
    unawaited(
      ref
          .read(chatViewModelProvider.notifier)
          .deleteMessageAttachment(
            messageId: messageId,
            attachmentId: attachment.id,
          ),
    );
  }
  return confirmed;
}
