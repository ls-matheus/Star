import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/domain/channel_settings_tab.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_confirm_sheet.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_dart/export.dart' hide ChannelType;

class DeleteChannelFlow {
  DeleteChannelFlow._();

  static Future<void> confirmAndDelete(
    BuildContext context,
    WidgetRef ref, {
    required Channel channel,
    VoidCallback? onDeleted,
  }) async {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String title = channelSettingsDeleteLabel(l10n, channel: channel);
    final String description = channel.isCategory
        ? l10n.channelSettingsDeleteCategoryConfirm(channel.name)
        : l10n.channelSettingsDeleteChannelConfirm(channel.name);
    final toast = ref.read(toastProvider.notifier);
    Future<void> performDelete() async {
      try {
        await ref
            .read(starClientProvider)
            .channels
            .deleteChannel(
              channelId: channel.id,
              body: const SudoVerificationSchema(),
            );
      } on Object catch (error) {
        await showApiErrorFromRoot(
          channel.isCategory
              ? ApiErrorAction.deleteCategory
              : ApiErrorAction.deleteChannel,
          error,
        );
        return;
      }
      onDeleted?.call();
      if (context.mounted) {
        Navigator.of(context).maybePop();
      }
      toast.show(
        StarToast(
          message: channel.isCategory
              ? l10n.categoryDeletedToast
              : l10n.channelDeletedToast,
          variant: StarToastVariant.success,
        ),
      );
    }

    final bool isMobile = isMobileLayout(context);
    if (isMobile) {
      await StarConfirmSheet.show(
        context,
        title: title,
        description: description,
        confirmLabel: title,
        isDanger: true,
        onConfirm: () => unawaited(performDelete()),
      );
      return;
    }
    await StarConfirmModal.show(
      context,
      title: title,
      description: description,
      confirmLabel: title,
      isDanger: true,
      onConfirm: () => unawaited(performDelete()),
    );
  }
}
