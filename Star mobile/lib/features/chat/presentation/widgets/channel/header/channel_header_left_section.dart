import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/gateway/providers/gateway_event_providers.dart';
import 'package:star_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/channel_topic_dialog.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/dm_header_avatar.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:star_app/features/chat/utils/channel_details_handheld.dart';
import 'package:star_app/features/chat/utils/channel_header_utils.dart';
import 'package:star_app/features/dm/domain/dm_channel_types.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/presentation/edit_group_dm_flow.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:star_app/features/profile/presentation/user_profile_sheet.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/providers/voice_session_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_state.dart';
import 'package:star_app/features/voice/utils/e2ee/e2ee_display.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_dart/gateway.dart';
import 'package:star_markdown/star_markdown.dart';

class ChannelHeaderLeftSection extends ConsumerStatefulWidget {
  const ChannelHeaderLeftSection({
    required this.channelId,
    required this.channel,
    required this.dm,
    required this.isPersonalNotes,
    required this.highContrast,
    super.key,
  });

  final String channelId;
  final Channel? channel;
  final DmConversation? dm;
  final bool isPersonalNotes;
  final bool highContrast;

  @override
  ConsumerState<ChannelHeaderLeftSection> createState() =>
      _ChannelHeaderLeftSectionState();
}

class _ChannelHeaderLeftSectionState
    extends ConsumerState<ChannelHeaderLeftSection> {
  bool _hoveringTitle = false;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool touchPrimary = isTouchPrimaryInput(ref);
    final bool showGroupPencil =
        widget.dm != null &&
        widget.dm!.isGroup &&
        (touchPrimary || _hoveringTitle);
    final String title = resolveChannelHeaderTitle(
      ref,
      channelId: widget.channelId,
      l10n: l10n,
      channel: widget.channel,
      dm: widget.dm,
      isPersonalNotes: widget.isPersonalNotes,
    );
    final String? topic = widget.channel?.topic?.trim();
    final bool hasTopic = topic != null && topic.isNotEmpty;
    final Color primaryColor = widget.highContrast
        ? Colors.white
        : context.colors.textPrimary;
    final Color mutedColor = widget.highContrast
        ? Colors.white.withValues(alpha: 0.8)
        : context.colors.textTertiary;

    final bool wideLayout = isWideLayout(context);
    final bool titleTappable =
        !wideLayout ||
        (widget.dm != null &&
            (widget.dm!.isGroup ||
                (!widget.dm!.isGroup && !widget.dm!.isPersonalNotes)));

    final Widget titleContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Row(
        children: [
          _buildLeadingIcon(context),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: context.textStyles.channelName.copyWith(
                      color: primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showGroupPencil) ...[
                  const SizedBox(width: 4),
                  PhosphorIcon(
                    PhosphorIconsFill.pencilSimple,
                    size: 16,
                    color: mutedColor,
                  ),
                ],
                if (widget.dm != null &&
                    isBotOrSystemDmRecipient(widget.dm!)) ...[
                  const SizedBox(width: 6),
                  StarUserTag(isSystem: widget.dm!.isSystem),
                ],
              ],
            ),
          ),
          if (hasTopic) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '•',
                style: context.textStyles.bodySmall.copyWith(
                  color: mutedColor,
                  fontSize: 13,
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: StarGestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(
                  showChannelTopicDialog(
                    context,
                    channelName: title,
                    topic: topic,
                    channelId: widget.channel!.id,
                  ),
                ),
                child: IgnorePointer(
                  child: MessageMarkdown(
                    data: topic,
                    channelId: widget.channel!.id,
                    guildId: widget.channel!.guildId,
                    markdownContext:
                        StarMarkdownContext.restrictedInlineReply,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    baseStyle: context.textStyles.bodySmall.copyWith(
                      color: mutedColor,
                      fontSize: 13,
                      height: 18 / 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveringTitle = true),
      onExit: (_) => setState(() => _hoveringTitle = false),
      cursor: titleTappable ? SystemMouseCursors.click : MouseCursor.defer,
      child: titleTappable
          ? InkWell(
              onTap: () => _handleTitleTap(context),
              borderRadius: BorderRadius.circular(6),
              child: titleContent,
            )
          : titleContent,
    );
  }

  void _handleTitleTap(BuildContext context) {
    if (!isWideLayout(context)) {
      unawaited(
        openHandheldChannelDetailsAndJump(
          context,
          ref: ref,
          container: ref.container,
          channel: widget.channel,
          dm: widget.dm,
        ),
      );
      return;
    }
    final DmConversation? dm = widget.dm;
    if (dm != null && dm.isGroup) {
      unawaited(EditGroupDmFlow.show(context, dm: dm));
      return;
    }
    if (dm != null && !dm.isGroup && !dm.isPersonalNotes) {
      unawaited(StarUserProfileSheet.show(context, userId: dm.recipientId));
      return;
    }
  }

  Widget _buildLeadingIcon(BuildContext context) {
    if (widget.isPersonalNotes) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: PhosphorIcon(
            PhosphorIconsFill.notePencil,
            size: 20,
            color: widget.highContrast
                ? Colors.white
                : context.colors.interactiveNormal,
          ),
        ),
      );
    }
    final Channel? channel = widget.channel;
    if (channel != null) {
      final int? effectivePermissionBits = ref.watch(
        channelPermissionCacheProvider(
          watchAccountUserId(ref),
        ).select((m) => m[channel.id]),
      );
      final VoiceSessionState voice = ref.watch(voiceSessionProvider);
      final Map<String, VoiceState> voiceStates = ref.watch(
        voiceStatesMapProvider(readAccountUserId(ref)),
      );
      final bool isVoiceChannel = channel.type == ChannelType.guildVoice;
      final Guild? guild = ref
          .watch(guildListViewModelProvider)
          .guilds
          .where((Guild g) => g.id == channel.guildId)
          .firstOrNull;
      final bool e2eeEncrypted =
          isVoiceChannel &&
          isVoiceChannelE2eeEncryptedForIcon(
            voiceStates: voiceStates,
            guildId: channel.guildId,
            channelId: channel.id,
            connectedVoiceGuildId: voice.guildId,
            connectedVoiceChannelId: voice.channelId,
            guildHasVoiceE2ee: guild?.hasVoiceE2ee ?? false,
          );
      return ChannelIcon(
        type: channel.type,
        channel: channel,
        effectivePermissionBits: effectivePermissionBits,
        e2eeEncrypted: e2eeEncrypted,
      );
    }
    final DmConversation? dm = widget.dm;
    if (dm != null) {
      return DmHeaderAvatar(dm: dm);
    }
    return PhosphorIcon(
      PhosphorIconsFill.chatCircle,
      size: 20,
      color: context.colors.interactiveNormal,
    );
  }
}
