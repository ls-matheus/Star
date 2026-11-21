import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/chat/providers/channel/channel_details_providers.dart';
import 'package:star_app/features/ui/bottom_sheet/star_confirm_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';

Future<bool?> showUnpinMessageConfirmSheet(
  BuildContext context,
  WidgetRef ref, {
  required String channelId,
  required String messageId,
}) {
  final l10n = StarLocalizations.of(context);
  return StarConfirmSheet.show(
    context,
    title: l10n.chatMessageUnpinConfirmTitle,
    description: l10n.chatMessageUnpinConfirmDescription,
    confirmLabel: l10n.chatMessageUnpinIt,
    isDanger: true,
    onConfirm: () {
      unawaited(
        ref
            .read(channelPinsRepositoryProvider)
            .unpinMessage(channelId: channelId, messageId: messageId)
            .catchError(
              (Object error) =>
                  showApiErrorFromRoot(ApiErrorAction.unpinMessage, error),
            ),
      );
    },
  );
}
