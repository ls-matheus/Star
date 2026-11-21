import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_confirm_preview.dart';
import 'package:star_app/features/chat/providers/channel/channel_details_providers.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';

Future<bool?> showPinMessageConfirmModal(
  BuildContext context,
  WidgetRef ref, {
  required Message message,
  String? guildId,
}) {
  final l10n = StarLocalizations.of(context);
  return StarConfirmModal.show(
    context,
    title: l10n.chatMessagePin,
    description: l10n.chatMessagePinConfirmDescription,
    confirmLabel: l10n.chatMessagePinConfirm,
    body: MessageConfirmPreview(message: message, guildId: guildId),
    onConfirm: () {
      unawaited(
        ref
            .read(channelPinsRepositoryProvider)
            .pinMessage(channelId: message.channelId, messageId: message.id)
            .catchError(
              (Object error) =>
                  showApiErrorFromRoot(ApiErrorAction.pinMessage, error),
            ),
      );
    },
  );
}
