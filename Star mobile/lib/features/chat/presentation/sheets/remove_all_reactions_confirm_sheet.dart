import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/chat/providers/core/chat_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_confirm_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<bool?> showRemoveAllReactionsConfirmSheet(
  BuildContext context,
  WidgetRef ref, {
  required String messageId,
}) {
  final l10n = StarLocalizations.of(context);
  return StarConfirmSheet.show(
    context,
    title: l10n.chatMessageRemoveAllReactionsConfirmTitle,
    description: l10n.chatMessageRemoveAllReactionsConfirmDescription,
    confirmLabel: l10n.chatMessageRemoveAllReactions,
    isDanger: true,
    onConfirm: () {
      unawaited(
        ref
            .read(chatViewModelProvider.notifier)
            .removeAllReactionsOnMessage(messageId),
      );
    },
  );
}
