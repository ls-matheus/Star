import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/limits/instance_limit_provider.dart';
import 'package:star_app/core/limits/limit_key.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/router/route_names.dart';
import 'package:star_app/features/channels/domain/announcement_follow.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/presentation/sheets/channel_follow_sheet.dart';
import 'package:star_app/features/channels/providers/channel_list_view_model.dart';
import 'package:star_app/features/channels/providers/unread_provider.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/channel_header_icon_button.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/channel_header_search_field.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/channel_notification_settings_button.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/channel_pins_overlay_button.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/oxygen_update_header_button.dart';
import 'package:star_app/features/chat/utils/channel_header_utils.dart';
import 'package:star_app/features/dm/domain/dm_channel_types.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/domain/group_dm_utils.dart';
import 'package:star_app/features/dm/presentation/add_friends_to_group_flow.dart';
import 'package:star_app/features/dm/presentation/create_dm_flow.dart';
import 'package:star_app/features/dm/providers/create_dm_view_model.dart';
import 'package:star_app/features/favorites/domain/favorite_guild_id.dart';
import 'package:star_app/features/favorites/providers/favorite_channels_provider.dart';
import 'package:star_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:star_app/features/mature_content/providers/mature_content_agreements_provider.dart';
import 'package:star_app/features/notifications/presentation/inbox_popout.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/threads/presentation/thread_header_buttons.dart';
import 'package:star_app/features/threads/utils/thread_title.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/utils/callkit/call_actions.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

class ChannelHeaderToolbar extends ConsumerWidget {
  const ChannelHeaderToolbar({
    required this.channelId,
    required this.channel,
    required this.dm,
    required this.isPersonalNotes,
    required this.isMemberListVisible,
    required this.showMessageActions,
    required this.highContrast,
    super.key,
  });

  final String channelId;
  final Channel? channel;
  final DmConversation? dm;
  final bool isPersonalNotes;
  final bool isMemberListVisible;
  final bool showMessageActions;
  final bool highContrast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showMessageActions) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: usesDesktopPointerUi(context) ? 8 : 0,
        children: [
          ..._buildCallButtons(context, ref),
          OxygenUpdateHeaderButton(highContrast: highContrast),
        ],
      );
    }

    final StarLocalizations l10n = StarLocalizations.of(context);
    final String? targetId = channel?.id ?? dm?.id;
    final bool hasUnreadPins =
        targetId != null &&
        (ref.watch(channelUnreadProvider(targetId)).value?.hasUnreadPins ??
            false);
    final bool matureGateUp =
        targetId != null && watchMatureContentGateUp(ref, targetId);
    final bool showPins =
        !matureGateUp && shouldShowPinsForContext(channel: channel, dm: dm);
    final bool showSearch =
        !matureGateUp && shouldShowSearchForContext(channel: channel, dm: dm);
    final bool showMembers = shouldShowMemberListToggle(
      channel: channel,
      dm: dm,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: usesDesktopPointerUi(context) ? 8 : 0,
      children: [
        if (channel != null && !isPersonalNotes && !channel!.isThread)
          buildChannelNotificationButton(channel: channel!),
        if (channel != null && showsThreadHeaderActions(channel))
          ThreadHeaderToolbarButtons(channel: channel!),
        ..._buildCallButtons(context, ref),
        if (ref.watch(
          guildPermissionsProvider(watchAccountUserId(ref)).select(
            (Map<String, int> permissions) =>
                canOfferAnnouncementFollow(channel, permissions),
          ),
        ))
          ChannelHeaderIconButton(
            icon: PhosphorIconsFill.megaphone,
            label: l10n.channelHeaderFollow,
            onPressed: () =>
                unawaited(ChannelFollowSheet.show(context, channel: channel!)),
          ),
        if (showPins && targetId != null)
          buildChannelPinsButton(
            channelId: targetId,
            guildId: channel?.guildId,
            hasUnreadPins: hasUnreadPins,
          ),
        if (dm != null &&
            dm!.isGroup &&
            !isPersonalNotes &&
            _shouldShowAddFriends(ref, dm!))
          ChannelHeaderIconButton(
            icon: PhosphorIconsFill.userPlus,
            label: l10n.groupDmWelcomeAddFriends,
            onPressed: () =>
                unawaited(AddFriendsToGroupFlow.show(context, ref, dm: dm!)),
          ),
        if (dm != null &&
            !dm!.isGroup &&
            !isPersonalNotes &&
            !dm!.isBot &&
            !dm!.isSystem)
          ChannelHeaderIconButton(
            icon: PhosphorIconsFill.userPlus,
            label: l10n.createGroupDm,
            onPressed: () => unawaited(
              CreateDmFlow.show(
                context,
                options: CreateDmOptions(
                  initialSelectedUserIds: dm!.remoteRecipientIds,
                  duplicateExcludeChannelId: dm!.id,
                ),
              ),
            ),
          ),
        if (_shouldShowFavorite(ref))
          _FavoriteStarButton(channel: channel, dm: dm),
        if (showMembers)
          ChannelHeaderIconButton(
            icon: PhosphorIconsFill.users,
            label: l10n.channelHeaderMemberList,
            isActive: isMemberListVisible,
            onPressed: () => ref
                .read(channelListViewModelProvider.notifier)
                .toggleMemberList(
                  channelId: channelId,
                  channelType: channel?.type,
                ),
          ),
        if (showSearch && targetId != null)
          ChannelHeaderSearchField(
            channelId: targetId,
            guildId: channel?.guildId,
            dm: dm,
            highContrast: highContrast,
          ),
        OxygenUpdateHeaderButton(highContrast: highContrast),
        if (isWideLayout(context))
          InboxPopoutButton(
            anchorBuilder:
                (
                  BuildContext context, {
                  required bool isOpen,
                  required VoidCallback toggle,
                }) => ChannelHeaderIconButton(
                  icon: PhosphorIconsFill.tray,
                  label: l10n.channelHeaderInbox,
                  isActive: isOpen,
                  onPressed: toggle,
                ),
          )
        else
          ChannelHeaderIconButton(
            icon: PhosphorIconsFill.tray,
            label: l10n.channelHeaderInbox,
            onPressed: () =>
                ref.read(starRouterProvider).go(RoutePaths.notificationsPath),
          ),
      ],
    );
  }

  List<Widget> _buildCallButtons(BuildContext context, WidgetRef ref) {
    final DmConversation? conversation = dm;
    if (conversation == null || !canStartDmCall(conversation)) {
      return const <Widget>[];
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    return <Widget>[
      ChannelHeaderIconButton(
        icon: PhosphorIconsFill.phone,
        label: l10n.dmVoiceCall,
        onPressed: () => _executeOutboundDmCall(
          ref: ref,
          context: context,
          dm: conversation,
        ),
      ),
      ChannelHeaderIconButton(
        icon: PhosphorIconsFill.videoCamera,
        label: l10n.userProfileVideoCall,
        onPressed: () => _executeOutboundDmCall(
          ref: ref,
          context: context,
          dm: conversation,
          startWithVideo: true,
        ),
      ),
    ];
  }

  bool _shouldShowAddFriends(WidgetRef ref, DmConversation dm) {
    final int maxRecipients = ref.read(
      instanceLimitProvider(LimitKeys.maxGroupDmRecipients),
    );
    return !isGroupDmFull(
      memberCount: dm.recipientCount,
      maxGroupDmRecipients: maxRecipients,
    );
  }

  bool _shouldShowFavorite(WidgetRef ref) {
    if (!ref.watch(
      appearancePreferencesProvider.select((s) => s.showFavorites),
    )) {
      return false;
    }
    if (isPersonalNotes) {
      return false;
    }
    final Channel? guildChannel = channel;
    if (guildChannel != null &&
        isThreadFeatureChannelType(guildChannel.type.wireValue)) {
      return false;
    }
    return channel != null || dm != null;
  }
}

class _FavoriteStarButton extends ConsumerWidget {
  const _FavoriteStarButton({required this.channel, required this.dm});

  final Channel? channel;
  final DmConversation? dm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? targetId = channel?.id ?? dm?.id;
    if (targetId == null) {
      return const SizedBox.shrink();
    }
    final bool isFavorite =
        ref.watch(favoriteChannelProvider(targetId)).asData?.value != null;
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarGestureDetector(
      onLongPress: () => _showHideFavorites(context, ref),
      child: ChannelHeaderIconButton(
        icon: isFavorite ? PhosphorIconsFill.star : PhosphorIconsBold.star,
        label: isFavorite
            ? l10n.favoritesRemoveFromFavorites
            : l10n.favoritesAddToFavorites,
        isActive: isFavorite,
        onPressed: () => _toggleFavorite(context, ref, isFavorite: isFavorite),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref, {
    required bool isFavorite,
  }) async {
    final String? targetId = channel?.id ?? dm?.id;
    if (targetId == null) {
      return;
    }
    final repository = ref.read(favoriteChannelsRepositoryProvider);
    if (isFavorite) {
      await repository.removeChannel(targetId);
    } else {
      await repository.addChannel(
        channelId: targetId,
        guildId: resolveFavoriteGuildId(
          channelGuildId: channel?.guildId,
          isDm: dm != null,
        ),
        nickname:
            (channel == null
                ? null
                : readThreadTitleText(
                    ref,
                    channel!,
                    StarLocalizations.of(context),
                  )) ??
            (dm == null
                ? null
                : dmConversationDisplayName(
                    StarLocalizations.of(context),
                    dm!,
                  )),
      );
    }
    if (!context.mounted) {
      return;
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    ref
        .read(toastProvider.notifier)
        .show(
          StarToast(
            message: isFavorite
                ? l10n.favoritesRemovedToast
                : l10n.favoritesAddedToast,
            variant: StarToastVariant.success,
          ),
        );
  }

  void _showHideFavorites(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    unawaited(
      StarBottomSheet.show<void>(
        context,
        title: l10n.favoritesTitle,
        variant: StarBottomSheetVariant.menu,
        builder: (sheetContext, close) => StarBottomSheetContent(
          child: StarBottomSheetMenuItem(
            label: l10n.favoritesHideConfirmTitle,
            icon: PhosphorIconsFill.eyeSlash,
            onTap: () {
              close();
              unawaited(
                ref
                    .read(appearancePreferencesProvider.notifier)
                    .setShowFavorites(value: false),
              );
              ref
                  .read(toastProvider.notifier)
                  .show(
                    StarToast(
                      message: l10n.favoritesHiddenToast,
                      variant: StarToastVariant.success,
                    ),
                  );
            },
          ),
        ),
      ),
    );
  }
}

void _executeOutboundDmCall({
  required WidgetRef ref,
  required BuildContext context,
  required DmConversation dm,
  bool startWithVideo = false,
}) {
  unawaited(() async {
    final String? selfId = ref.read(currentUserIdProvider);
    final List<String> ringTargets = dm.remoteRecipientIds
        .where((String id) => selfId == null || id != selfId)
        .toList();
    final StartDirectVoiceCallResult r = await startDirectVoiceCall(
      ref,
      context,
      dm.id,
      outboundRingRecipients: ringTargets.isEmpty ? null : ringTargets,
      startWithVideo: startWithVideo,
    );
    if (!context.mounted) {
      return;
    }
    await explainDirectCallFailure(context, r);
  }());
}
