import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/domain/dm_list_message_preview.dart';
import 'package:star_app/features/friends/providers/blocked_user_ids_provider.dart';
import 'package:star_app/features/friends/providers/friend_providers.dart';
import 'package:star_app/features/mature_content/providers/mature_content_agreements_provider.dart';
import 'package:star_app/features/profile/providers/user_presence_provider.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/widgets/custom_status_display.dart';
import 'package:star_markdown/star_markdown.dart';

class DmListTileSubtext extends ConsumerWidget {
  const DmListTileSubtext({
    required this.conversation,
    required this.style,
    required this.hasUnread,
    required this.currentUserId,
    super.key,
  });

  final DmConversation conversation;
  final TextStyle style;
  final bool hasUnread;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DmMessagePreviewMode previewMode = ref.watch(
      appearancePreferencesProvider.select(
        (state) => state.dmMessagePreviewMode,
      ),
    );
    if (shouldShowDmMessagePreview(mode: previewMode, hasUnread: hasUnread)) {
      if (conversation.isGroup &&
          conversation.lastMessageId != null &&
          watchMatureChannelLocked(ref, conversation.id)) {
        return Text(
          StarLocalizations.of(context).matureMessageHiddenPreview,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      }
      final String? authorId = conversation.lastMessageAuthorId;
      if (authorId != null &&
          authorId != currentUserId &&
          ref.watch(
            blockedUserIdsProvider.select(
              (Set<String> ids) => ids.contains(authorId),
            ),
          )) {
        return Text(
          StarLocalizations.of(context).chatBlockedMessagesCollapsed(1),
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      }
      final String? authorFriendNickname =
          authorId != null && authorId.isNotEmpty && authorId != currentUserId
          ? ref.watch(
              friendNicknameProvider(
                authorId,
              ).select((AsyncValue<String?> value) => value.value),
            )
          : null;
      final DmListMessagePreview? preview = resolveDmListMessagePreview(
        l10n: StarLocalizations.of(context),
        conversation: conversation,
        currentUserId: currentUserId,
        authorFriendNickname: authorFriendNickname,
      );
      if (preview != null) {
        return DmListMessagePreviewRow(
          preview: preview,
          channelId: conversation.id,
          messageId: conversation.lastMessageId,
          style: style,
          attachmentLabel: StarLocalizations.of(
            context,
          ).dmListSentAnAttachment,
        );
      }
    }
    if (conversation.isGroup) {
      return const SizedBox.shrink();
    }
    final String? customStatus = ref.watch(
      userPresenceProvider(
        conversation.recipientId,
      ).select((UserPresence? presence) => presence?.customStatus),
    );
    return CustomStatusDisplay(
      stored: customStatus,
      maxLines: 1,
      emojiSize: 14,
      textStyle: style,
    );
  }
}

class DmListMessagePreviewRow extends StatelessWidget {
  const DmListMessagePreviewRow({
    required this.preview,
    required this.channelId,
    required this.messageId,
    required this.style,
    required this.attachmentLabel,
    super.key,
  });

  final DmListMessagePreview preview;
  final String channelId;
  final String? messageId;
  final TextStyle style;
  final String attachmentLabel;

  @override
  Widget build(BuildContext context) {
    final DmListMessagePreview messagePreview = preview;
    if (messagePreview is DmListMarkdownMessagePreview) {
      final DmListMarkdownMessagePreview markdownPreview = messagePreview;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(markdownPreview.authorPrefix, style: style, maxLines: 1),
          Expanded(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: MessageMarkdown(
                  data: markdownPreview.content,
                  channelId: channelId,
                  messageId: messageId,
                  markdownContext: StarMarkdownContext.restrictedInlineReply,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  baseStyle: style,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (messagePreview is DmListSystemMessagePreview) {
      return Text(
        messagePreview.text,
        style: style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
    final DmListAttachmentMessagePreview attachmentPreview =
        messagePreview as DmListAttachmentMessagePreview;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(attachmentPreview.authorPrefix, style: style, maxLines: 1),
        Expanded(
          child: Text(
            attachmentLabel,
            style: style.copyWith(fontStyle: FontStyle.italic),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
