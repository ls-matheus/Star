import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/features/dm/domain/dm_channel_types.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/presentation/widgets/group_dm_avatar.dart';
import 'package:star_app/features/dm/providers/dm_view_model.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/voice/voice_channel_join_button.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_e2ee_indicator.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_join_empty_state.dart';
import 'package:star_app/features/voice/utils/connection/connection_actions.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/chat_context_utils.dart';

class VoiceCallJoinEmptyState extends ConsumerWidget {
  const VoiceCallJoinEmptyState({
    required this.channelId,
    required this.participantPreviewCount,
    super.key,
  });

  final String channelId;
  final int participantPreviewCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final conversations = ref.watch(
      dmViewModelProvider.select((s) => s.conversations),
    );
    final DmConversation? dm = findDmById(conversations, channelId);
    final String headline = dm == null
        ? l10n.dmVoiceFullscreenTitle
        : dmConversationDisplayName(l10n, dm);
    final bool canJoinVoice = dm != null && canStartDmCall(dm);

    return VoiceJoinEmptyState(
      childBuilder: (VoiceJoinEmptyLayout layout) => <Widget>[
        VoiceJoinEmptyMark(
          layout: layout,
          child: _buildMarkChild(context, dm, layout.iconSize),
        ),
        VoiceJoinEmptyTitle(title: headline, layout: layout),
        if (participantPreviewCount > 0)
          VoiceJoinEmptySubtitle(
            text: l10n.voiceChannelParticipantCount(participantPreviewCount),
          ),
        VoiceChannelJoinButton(
          label: l10n.voiceCallJoin,
          disabledTooltip: canJoinVoice
              ? null
              : l10n.directVoiceCallNotEligible,
          onPressed: canJoinVoice
              ? () {
                  unawaited(
                    joinVoiceChannelWithConfirmation(
                      ref: ref,
                      context: context,
                      guildId: null,
                      channelId: channelId,
                    ),
                  );
                }
              : null,
        ),
        VoiceE2eeIndicator(
          guildId: null,
          channelId: channelId,
          variant: VoiceE2eeIndicatorVariant.call,
          includeTopPadding: false,
        ),
      ],
    );
  }

  Widget _buildMarkChild(
    BuildContext context,
    DmConversation? dm,
    double iconSize,
  ) {
    if (dm == null) {
      return PhosphorIcon(
        PhosphorIconsFill.phone,
        size: iconSize,
        color: voiceJoinEmptyMarkForeground(context),
      );
    }
    if (dm.isGroup) {
      return GroupDmAvatar.conversation(dm, size: iconSize);
    }
    return ClipOval(
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: StarAvatar.user(
          fallbackText: dm.recipientName,
          userId: dm.recipientId,
          imageUrl: StarMediaUrl.userAvatar(
            userId: dm.recipientId,
            hash: dm.recipientAvatar,
            animated: true,
          ),
          status: dm.recipientStatus,
          size: iconSize,
          showStatus: false,
        ),
      ),
    );
  }
}
