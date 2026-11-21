import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/dio_error_message.dart';
import 'package:star_app/core/router/navigate_to_content.dart';
import 'package:star_app/core/router/route_names.dart';
import 'package:star_app/features/channels/providers/channel_list_view_model.dart';
import 'package:star_app/features/channels/providers/channel_providers.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_providers.dart';
import 'package:star_app/features/settings/presentation/sheets/claim_account_sheet.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

enum CreateCommunityFailureKind { apiError, maxGuilds, singleCommunity }

class CreateCommunityException implements Exception {
  const CreateCommunityException({required this.kind, required this.message});

  final CreateCommunityFailureKind kind;
  final String message;

  @override
  String toString() => message;
}

Future<void> createCommunity({
  required BuildContext context,
  required WidgetRef ref,
  required String name,
  required StarLocalizations l10n,
  String? iconDataUri,
  TemplateSerializedGuild? template,
}) async {
  try {
    final GuildResponse guild = await ref
        .read(guildRepositoryProvider)
        .createGuild(name: name, iconDataUri: iconDataUri, template: template);
    await ref.read(channelRepositoryProvider).getChannels(guild.id);
    final Guild? localGuild = await ref.read(
      guildByIdProvider(guild.id).future,
    );
    if (localGuild != null) {
      ref
          .read(channelListViewModelProvider.notifier)
          .loadChannels(guild.id, guild: localGuild);
    }
    navigateToContentVia(ref, RoutePaths.guild(guild.id));
  } on CreateCommunityException {
    rethrow;
  } on DioException catch (e) {
    final String? code = apiErrorCodeFromDioException(e);
    switch (code) {
      case 'UNCLAIMED_ACCOUNT_CANNOT_CREATE_GUILDS':
        if (context.mounted) {
          await ClaimAccountSheet.show(context, ref);
        }
        throw CreateCommunityException(
          kind: CreateCommunityFailureKind.apiError,
          message: l10n.addGuildCreateClaimDescription,
        );
      case 'SINGLE_COMMUNITY_CANNOT_CREATE_GUILDS':
        throw CreateCommunityException(
          kind: CreateCommunityFailureKind.singleCommunity,
          message: l10n.addGuildCreateSingleCommunityBlocked,
        );
      case 'MAX_GUILDS_REACHED':
      case 'MAX_GUILDS':
        throw CreateCommunityException(
          kind: CreateCommunityFailureKind.maxGuilds,
          message: l10n.discoveryJoinErrorMaxGuildsMessage,
        );
      case 'GUILD_TEMPLATE_INVALID':
        throw CreateCommunityException(
          kind: CreateCommunityFailureKind.apiError,
          message: l10n.addGuildImportTemplateInvalid,
        );
      default:
        throw CreateCommunityException(
          kind: CreateCommunityFailureKind.apiError,
          message: userFacingErrorMessage(e, l10n.addGuildCreateFailed),
        );
    }
  } on Object {
    throw CreateCommunityException(
      kind: CreateCommunityFailureKind.apiError,
      message: l10n.addGuildCreateFailed,
    );
  }
}

void showCreateCommunityFailureToast({
  required WidgetRef ref,
  required CreateCommunityException error,
  required StarLocalizations l10n,
}) {
  if (error.kind == CreateCommunityFailureKind.maxGuilds) {
    ref
        .read(toastProvider.notifier)
        .show(
          StarToast(
            message: error.message,
            variant: StarToastVariant.warning,
          ),
        );
    return;
  }
  ref
      .read(toastProvider.notifier)
      .show(
        StarToast(message: error.message, variant: StarToastVariant.danger),
      );
}
