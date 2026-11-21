import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/permissions/permission.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/presentation/channel_settings/widgets/channel_settings_status_slate.dart';
import 'package:star_app/features/channels/presentation/channel_settings/widgets/channel_webhook_list_item.dart';
import 'package:star_app/features/channels/providers/channel_webhooks_provider.dart';
import 'package:star_app/features/channels/utils/webhook_utils.dart';
import 'package:star_app/features/settings/providers/guild/guild_settings_tab_providers.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_dart/export.dart' hide ChannelType;

class ChannelWebhooksWidget extends ConsumerWidget {
  const ChannelWebhooksWidget({
    required this.channel,
    required this.permissions,
    this.scrollController,
    super.key,
  });

  final Channel channel;
  final int permissions;
  final ScrollController? scrollController;

  bool get _canManageWebhooks =>
      hasPermission(permissions, Permission.manageWebhooks);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final Widget header = _buildHeader(context, l10n);
    if (!isGuildTextBasedChannelType(channel.type)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          header,
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.s4,
              0,
              context.layout.s4,
              context.layout.s4,
            ),
            child: _buildMessageBox(
              context,
              l10n.channelSettingsWebhooksUnsupported,
            ),
          ),
        ],
      );
    }
    if (!_canManageWebhooks) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          header,
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.s4,
              0,
              context.layout.s4,
              context.layout.s4,
            ),
            child: _buildMessageBox(
              context,
              l10n.channelSettingsWebhooksPermissionRequired(
                l10n.permissionManageWebhooks,
              ),
            ),
          ),
        ],
      );
    }
    final AsyncValue<List<WebhookResponse>> webhooksAsync = ref.watch(
      channelWebhooksProvider(channel.id),
    );
    return webhooksAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          header,
          _buildCreateButton(context, l10n, ref, isLoading: true),
          const Expanded(child: Center(child: StarLoadingSpinner())),
        ],
      ),
      error: (Object error, StackTrace stackTrace) => _buildStatusShell(
        context,
        l10n: l10n,
        ref: ref,
        child: ChannelSettingsStatusSlate(
          icon: PhosphorIconsFill.warningOctagon,
          title: l10n.channelSettingsWebhooksLoadFailedTitle,
          description: l10n.channelSettingsWebhooksLoadFailedDescription,
          actionLabel: l10n.guildSettingsInvitesTryAgain,
          onAction: () => unawaited(
            ref.read(channelWebhooksProvider(channel.id).notifier).reload(),
          ),
        ),
      ),
      data: (List<WebhookResponse> webhooks) {
        final List<WebhookResponse> incoming = <WebhookResponse>[
          for (final WebhookResponse webhook in webhooks)
            if (!isChannelFollowerWebhook(webhook)) webhook,
        ];
        final List<WebhookResponse> followed = <WebhookResponse>[
          for (final WebhookResponse webhook in webhooks)
            if (isChannelFollowerWebhook(webhook)) webhook,
        ];
        if (incoming.isEmpty && followed.isEmpty) {
          return _buildStatusShell(
            context,
            l10n: l10n,
            ref: ref,
            child: ChannelSettingsStatusSlate(
              icon: PhosphorIconsFill.robot,
              title: l10n.channelSettingsWebhooksEmpty,
              description: l10n.channelSettingsWebhooksEmptyDescription,
              actionLabel: l10n.channelSettingsCreateWebhook,
              onAction: () => unawaited(_createWebhook(context, ref, l10n)),
            ),
          );
        }
        final List<Channel> availableChannels = _resolveTextChannels(ref);
        final Map<String, String> channelNames = <String, String>{
          for (final Channel item in availableChannels) item.id: item.name,
        };
        return CustomScrollView(
          controller: scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(child: header),
            SliverToBoxAdapter(child: _buildCreateButton(context, l10n, ref)),
            if (incoming.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.layout.s4,
                  0,
                  context.layout.s4,
                  context.layout.s4,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final WebhookResponse webhook = incoming[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: context.layout.s3),
                      child: ChannelWebhookListItem(
                        channelId: channel.id,
                        webhook: webhook,
                        channelName:
                            channelNames[webhook.channelId] ?? channel.name,
                        availableChannels: availableChannels,
                      ),
                    );
                  }, childCount: incoming.length),
                ),
              ),
            if (followed.isNotEmpty) ...<Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.layout.s4,
                    context.layout.s2,
                    context.layout.s4,
                    context.layout.s2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.channelSettingsFollowedChannels,
                        style: context.textStyles.label,
                      ),
                      SizedBox(height: context.layout.s1),
                      Text(
                        l10n.channelSettingsFollowedChannelsDescription,
                        style: context.textStyles.smallText.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.layout.s4,
                  0,
                  context.layout.s4,
                  context.layout.s4,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((
                    BuildContext context,
                    int index,
                  ) {
                    final WebhookResponse webhook = followed[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: context.layout.s3),
                      child: ChannelWebhookListItem(
                        channelId: channel.id,
                        webhook: webhook,
                        channelName:
                            channelNames[webhook.channelId] ?? channel.name,
                        availableChannels: availableChannels,
                      ),
                    );
                  }, childCount: followed.length),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatusShell(
    BuildContext context, {
    required StarLocalizations l10n,
    required WidgetRef ref,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeader(context, l10n),
        _buildCreateButton(context, l10n, ref),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, StarLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.s4,
        context.layout.s4,
        context.layout.s4,
        context.layout.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.channelSettingsTabWebhooks,
            style: context.textStyles.heading.copyWith(
              fontSize: 18,
              color: context.colors.textChat,
            ),
          ),
          SizedBox(height: context.layout.s1),
          Text(
            l10n.channelSettingsWebhooksDescription,
            style: context.textStyles.bodyMedium.copyWith(
              color: context.colors.textPrimaryMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBox(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        message,
        style: context.textStyles.bodySmall.copyWith(
          color: context.colors.textPrimaryMuted,
        ),
      ),
    );
  }

  Widget _buildCreateButton(
    BuildContext context,
    StarLocalizations l10n,
    WidgetRef ref, {
    bool isLoading = false,
  }) {
    if (!_canManageWebhooks || !isGuildTextBasedChannelType(channel.type)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.s4,
        0,
        context.layout.s4,
        context.layout.s4,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: StarButton.primary(
          onPressed: isLoading
              ? null
              : () => unawaited(_createWebhook(context, ref, l10n)),
          label: l10n.channelSettingsCreateWebhook,
          size: StarButtonSize.small,
          fitContent: true,
        ),
      ),
    );
  }

  List<Channel> _resolveTextChannels(WidgetRef ref) {
    final AsyncValue<List<Channel>> channelsAsync = ref.watch(
      guildSettingsChannelsProvider(channel.guildId),
    );
    final List<Channel>? channels = channelsAsync.value;
    if (channels == null) {
      return <Channel>[];
    }
    return channels
        .where((Channel item) => isGuildTextBasedChannelType(item.type))
        .toList();
  }

  Future<void> _createWebhook(
    BuildContext context,
    WidgetRef ref,
    StarLocalizations l10n,
  ) async {
    try {
      await ref
          .read(channelWebhooksProvider(channel.id).notifier)
          .createWebhook(name: generateWebhookName());
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.channelSettingsWebhookCreated,
              variant: StarToastVariant.success,
            ),
          );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      await showApiError(context, ApiErrorAction.createWebhook, error);
    }
  }
}
