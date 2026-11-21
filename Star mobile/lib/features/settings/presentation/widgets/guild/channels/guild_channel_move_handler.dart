import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/domain/channel_move_operation.dart';
import 'package:star_app/features/settings/providers/guild/guild_channel_settings_providers.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> performGuildChannelMove({
  required WidgetRef ref,
  required BuildContext context,
  required String guildId,
  required ChannelMoveComputation computation,
  required List<Channel> currentChannels,
}) async {
  try {
    await ref
        .read(guildChannelSettingsActionsProvider(guildId).notifier)
        .moveChannel(
          operation: computation.operation,
          currentChannels: currentChannels,
          optimisticChannels: computation.updatedChannels,
        );
  } on Object catch (_) {
    if (!context.mounted) {
      return;
    }
    ref
        .read(toastProvider.notifier)
        .show(
          StarToast(
            message: StarLocalizations.of(context).genericError,
            variant: StarToastVariant.danger,
          ),
        );
  }
}
