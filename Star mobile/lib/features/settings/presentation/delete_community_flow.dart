import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/router/route_names.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/features/guilds/utils/leave_guild_action.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_confirm_sheet.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:go_router/go_router.dart';

class DeleteCommunityFlow {
  DeleteCommunityFlow._();

  static Future<void> confirmAndDelete(
    BuildContext context,
    WidgetRef ref, {
    required String guildId,
  }) async {
    if (ref
        .read(instanceRuntimeConfigProvider)
        .isStockCommunityGuild(guildId)) {
      talker.info('[Guild] Delete skipped for stock community guild');
      return;
    }

    final StarLocalizations l10n = StarLocalizations.of(context);
    final String title = l10n.guildSettingsDeleteCommunity;
    final String description = l10n.guildSettingsDeleteCommunityConfirm;
    final bool? confirmed = isMobileLayout(context)
        ? await StarConfirmSheet.show(
            context,
            title: title,
            description: description,
            confirmLabel: title,
            isDanger: true,
            onConfirm: () {},
          )
        : await StarConfirmModal.show(
            context,
            title: title,
            description: description,
            confirmLabel: title,
            isDanger: true,
            onConfirm: () {},
          );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final toast = ref.read(toastProvider.notifier);
    try {
      await deleteGuildAndCleanup(ref, guildId);
    } on Object catch (error, stack) {
      talker.error('[Guild] Failed to delete community', error, stack);
      if (context.mounted) {
        await showApiError(context, ApiErrorAction.deleteCommunity, error);
      }
      return;
    }

    toast.show(
      StarToast(
        message: l10n.guildSettingsCommunityDeleted,
        variant: StarToastVariant.success,
      ),
    );
    if (!context.mounted) {
      return;
    }
    final GoRouter router = GoRouter.of(context);
    if (ModalRoute.of(context) is PopupRoute) {
      Navigator.of(context).pop();
    }
    router.go(RoutePaths.me);
  }
}
