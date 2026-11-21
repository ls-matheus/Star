import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/dio_error_message.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/announcement_follow.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/providers/core/chat_providers.dart';
import 'package:star_app/features/ui/bottom_sheet/star_confirm_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

String? formatRetryWait(StarLocalizations l10n, int? retryAfterMs) {
  if (retryAfterMs == null || retryAfterMs <= 0) {
    return null;
  }
  final int seconds = (retryAfterMs / 1000).ceil();
  if (seconds < 60) {
    return l10n.durationSeconds(seconds);
  }
  return l10n.durationMinutes((seconds / 60).ceil());
}

Future<bool> confirmPublishMessage(BuildContext context) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final bool? confirmed = await StarConfirmSheet.show(
    context,
    title: l10n.chatMessagePublishConfirmTitle,
    description: l10n.chatMessagePublishConfirmBody,
    confirmLabel: l10n.chatMessagePublish,
  );
  return confirmed ?? false;
}

Future<bool> confirmPublishedMessageEdit(BuildContext context) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final bool? confirmed = await StarConfirmSheet.show(
    context,
    title: l10n.chatMessageEditPublishedTitle,
    description: l10n.chatMessageEditPublishedBody,
    confirmLabel: l10n.chatMessageEditPublishedSave,
  );
  return confirmed ?? false;
}

Future<void> publishMessage({
  required WidgetRef ref,
  required BuildContext context,
  required Message message,
}) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  if (message.isCrossposted) {
    ref
        .read(toastProvider.notifier)
        .show(
          StarToast(
            message: l10n.chatMessageAlreadyPublished,
            variant: StarToastVariant.warning,
          ),
        );
    return;
  }
  final bool confirmed = await confirmPublishMessage(context);
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    await ref
        .read(messageRepositoryProvider)
        .crosspostMessage(channelId: message.channelId, messageId: message.id);
    if (!context.mounted) {
      return;
    }
    ref
        .read(toastProvider.notifier)
        .show(
          StarToast(
            message: l10n.chatMessagePublishedToast,
            variant: StarToastVariant.success,
          ),
        );
  } on DioException catch (error) {
    if (!context.mounted) {
      return;
    }
    final String? code = apiErrorCodeFromDioException(error);
    if (code == kMessageAlreadyCrossposted) {
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.chatMessageAlreadyPublished,
              variant: StarToastVariant.warning,
            ),
          );
      return;
    }
    if (code == kMessageCrosspostRateLimited) {
      await showPublishLimitSheet(
        context,
        retryAfterMs: retryAfterMsFromDioException(error),
      );
      return;
    }
    await _showPublishFailed(context, l10n, error);
  }
}

Future<void> showPublishLimitSheet(
  BuildContext context, {
  required int? retryAfterMs,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final String? wait = formatRetryWait(l10n, retryAfterMs);
  return StarModal.show<void>(
    context,
    title: l10n.chatMessagePublishLimitTitle,
    centered: true,
    builder: (BuildContext dialogContext, VoidCallback close) {
      return Text(
        wait == null
            ? l10n.chatMessagePublishLimitUnknown
            : l10n.chatMessagePublishLimitBody(wait),
        style: dialogContext.textStyles.bodySmall.copyWith(height: 1.4),
      );
    },
    actionsBuilder: (void Function([void]) pop) => <Widget>[
      StarButton.primary(onPressed: () => pop(), label: l10n.uiUnderstood),
    ],
  );
}

Future<void> showPublishedEditLimitSheet(
  BuildContext context, {
  required int? retryAfterMs,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final String? wait = formatRetryWait(l10n, retryAfterMs);
  return StarModal.show<void>(
    context,
    title: l10n.chatMessageEditLimitTitle,
    centered: true,
    builder: (BuildContext dialogContext, VoidCallback close) {
      return Text(
        wait == null
            ? l10n.chatMessageEditLimitUnknown
            : l10n.chatMessageEditLimitBody(wait),
        style: dialogContext.textStyles.bodySmall.copyWith(height: 1.4),
      );
    },
    actionsBuilder: (void Function([void]) pop) => <Widget>[
      StarButton.primary(onPressed: () => pop(), label: l10n.uiUnderstood),
    ],
  );
}

Future<void> _showPublishFailed(
  BuildContext context,
  StarLocalizations l10n,
  DioException error,
) {
  return StarModal.show<void>(
    context,
    title: l10n.chatMessagePublishFailedTitle,
    centered: true,
    builder: (BuildContext dialogContext, VoidCallback close) {
      return Text(
        userFacingErrorMessage(error, l10n.chatMessagePublishFailedBody),
        style: dialogContext.textStyles.bodySmall.copyWith(height: 1.4),
      );
    },
    actionsBuilder: (void Function([void]) pop) => <Widget>[
      StarButton.primary(onPressed: () => pop(), label: l10n.uiUnderstood),
    ],
  );
}
