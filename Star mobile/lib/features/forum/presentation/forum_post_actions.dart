import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/permissions/thread_permissions.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/chat/domain/chat_fullscreen_video_launch_context.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/media/chat_mobile_fullscreen_video.dart';
import 'package:star_app/features/chat/utils/media/media_dimension_utils.dart';
import 'package:star_app/features/forum/data/forum_repository.dart';
import 'package:star_app/features/forum/domain/forum_channel.dart';
import 'package:star_app/features/forum/presentation/widgets/forum_post_card.dart';
import 'package:star_app/features/forum/presentation/widgets/forum_tag_chip.dart';
import 'package:star_app/features/forum/providers/forum_first_messages_provider.dart';
import 'package:star_app/features/moderation/domain/iar_context.dart';
import 'package:star_app/features/moderation/presentation/report_flow/open_report_flow.dart';
import 'package:star_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:star_app/features/threads/presentation/thread_menu_sheet.dart';
import 'package:star_app/features/threads/providers/thread_ui_providers.dart';
import 'package:star_app/features/threads/utils/thread_actions.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/media_viewer/attachment_media_viewer.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/export.dart' hide ChannelType;

Future<void> openForumPost(BuildContext context, WidgetRef ref, Channel post) =>
    openThread(context, ref, post, fromParent: true);

void openForumPostMedia(
  BuildContext context,
  WidgetRef ref, {
  required Channel forum,
  required Channel post,
  required Message message,
  required Attachment attachment,
  required VoidCallback onViewPost,
}) {
  if (attachment.isVideo) {
    unawaited(
      showChatMobileFullscreenVideo(
        context,
        launchContext: ChatFullscreenVideoLaunchContext.fromAttachment(
          attachment: attachment,
          layoutDimensions: mediaDimensionsForSize(
            ref.read(chatPreferencesProvider).attachmentMediaDimensionSize,
          ),
          downloadsHidden: forumHidesMediaDownloads(forum),
          onViewPost: onViewPost,
        ),
      ),
    );
    return;
  }
  final List<Attachment> images = forumViewerImages(message);
  final int index = images.indexOf(attachment);
  unawaited(
    showAttachmentMediaViewer(
      context,
      items: images.map(AttachmentMediaViewerItem.fromAttachment).toList(),
      initialIndex: index < 0 ? 0 : index,
      channelId: post.id,
      downloadsHidden: forumHidesMediaDownloads(forum),
      onViewPost: onViewPost,
    ),
  );
}

Future<void> toggleForumDefaultReaction(
  BuildContext context,
  WidgetRef ref,
  Channel forum,
  ForumPostCardData data,
) async {
  final DefaultReactionEmojiResponse? reaction = forumDefaultReaction(forum);
  final Message? message = data.firstMessage;
  if (reaction == null || message == null) {
    return;
  }
  final Reaction? current = forumDefaultReactionState(message, reaction);
  final bool add = !(current?.hasReacted ?? false);
  final String? emojiId = reaction.emojiId;
  final String? storedName =
      emojiId != null &&
          (current?.emoji ?? '').isEmpty &&
          (reaction.emojiName ?? '').isEmpty
      ? (await ref.read(starDatabaseProvider).guildEmojiDao.getById(emojiId))
            ?.name
      : null;
  if (!context.mounted) {
    return;
  }
  final String key = forumReactionKey(
    emojiId: emojiId,
    emojiName: reaction.emojiName,
    reactedName: current?.emoji,
    storedName: storedName,
  );
  final ForumFirstMessages firstMessages = ref.read(
    forumFirstMessagesProvider(readAccountUserId(ref)).notifier,
  );
  void apply({required bool value}) => firstMessages.applyOwnReaction(
    postId: data.post.id,
    emojiId: reaction.emojiId,
    emojiName: <String?>[reaction.emojiName, current?.emoji, storedName]
        .whereType<String>()
        .firstWhere((String name) => name.isNotEmpty, orElse: () => ''),
    add: value,
  );
  final StarLocalizations l10n = StarLocalizations.of(context);
  apply(value: add);
  try {
    await ref
        .read(forumRepositoryProvider)
        .reactToPost(
          guildId: forum.guildId,
          postId: data.post.id,
          emoji: key,
          add: add,
        );
  } on Object catch (error) {
    apply(value: !add);
    showThreadToast(
      ref,
      threadErrorText(l10n, error),
      variant: StarToastVariant.danger,
    );
  }
}

Future<bool> updateForumPost(
  BuildContext context,
  WidgetRef ref,
  Channel post,
  Map<String, Object?> patch, {
  String? successMessage,
}) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  try {
    await ref
        .read(forumRepositoryProvider)
        .updatePost(guildId: post.guildId, postId: post.id, patch: patch);
  } on Object catch (error) {
    showThreadToast(
      ref,
      threadErrorText(l10n, error),
      variant: StarToastVariant.danger,
    );
    return false;
  }
  if (successMessage != null) {
    showThreadToast(ref, successMessage);
  }
  return true;
}

Future<void> showForumPostActionsSheet(
  BuildContext context,
  WidgetRef hostRef, {
  required Channel forum,
  required Channel post,
  required String title,
}) => StarBottomSheet.show<void>(
  context,
  title: title,
  variant: StarBottomSheetVariant.menu,
  builder: (BuildContext sheetContext, VoidCallback close) => _ForumPostActions(
    hostContext: context,
    hostRef: hostRef,
    forum: forum,
    post: post,
    close: close,
  ),
);

class _ForumPostActions extends ConsumerWidget {
  const _ForumPostActions({
    required this.hostContext,
    required this.hostRef,
    required this.forum,
    required this.post,
    required this.close,
  });

  final BuildContext hostContext;
  final WidgetRef hostRef;
  final Channel forum;
  final Channel post;
  final VoidCallback close;

  void _run(Future<void> Function() action) {
    close();
    unawaited(action());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final ThreadActorContext? actor = ref.watch(
      threadActorContextProvider(post.id),
    );
    final bool moderator = actor != null && isThreadModeratorFor(actor);
    final bool pinned = isPinnedPost(post);
    final bool canPin =
        moderator &&
        !isPostArchived(post) &&
        threadPatchRequirement(
              ThreadPatch(
                flags: pinned
                    ? (post.flags ?? 0) & ~channelFlagPinned
                    : (post.flags ?? 0) | channelFlagPinned,
              ),
              post.flags ?? 0,
              actor,
            ) ==
            null;
    final bool canEditTags =
        actor != null &&
        forumAvailableTags(forum).isNotEmpty &&
        canSetTags(actor, touchesModeratedTag: false) == null;
    final Message? firstMessage = ref.watch(
      forumFirstMessagesProvider(watchAccountUserId(ref)),
    )[post.id];
    final bool canReport =
        firstMessage != null &&
        firstMessage.authorId != ref.watch(currentUserIdProvider);
    final List<List<Widget>> threadGroups = buildThreadMenuGroups(
      context: context,
      ref: ref,
      thread: post,
      hostContext: hostContext,
      hostRef: hostRef,
      run: _run,
      includeMarkRead: false,
    );
    return ListView(
      shrinkWrap: true,
      padding: StarBottomSheet.scrollViewPadding(
        context,
        padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
      ),
      children: <Widget>[
        StarBottomSheetGroupColumn(
          children: <Widget>[
            StarMenuGroup(
              children: <Widget>[
                StarBottomSheetMenuItem(
                  icon: PhosphorIconsBold.arrowSquareOut,
                  label: l10n.forumOpenPost,
                  onTap: () =>
                      _run(() => openForumPost(hostContext, hostRef, post)),
                ),
                if (canEditTags)
                  StarBottomSheetMenuItem(
                    icon: PhosphorIconsBold.tag,
                    label: l10n.forumEditTags,
                    onTap: () => _run(
                      () => showForumPostTagsSheet(
                        hostContext,
                        forum: forum,
                        post: post,
                        moderator: moderator,
                      ),
                    ),
                  ),
                if (canPin)
                  StarBottomSheetMenuItem(
                    icon: pinned
                        ? PhosphorIconsBold.pushPinSlash
                        : PhosphorIconsBold.pushPin,
                    label: pinned ? l10n.forumUnpinPost : l10n.forumPinPost,
                    onTap: () => _run(
                      () => updateForumPost(
                        hostContext,
                        hostRef,
                        post,
                        <String, Object?>{
                          'flags': pinned
                              ? (post.flags ?? 0) & ~channelFlagPinned
                              : (post.flags ?? 0) | channelFlagPinned,
                        },
                      ),
                    ),
                  ),
                StarBottomSheetMenuItem(
                  icon: PhosphorIconsBold.checks,
                  label: l10n.forumMarkPostRead,
                  onTap: () => _run(() => markThreadRead(hostRef, post)),
                ),
                if (canReport)
                  StarBottomSheetMenuItem(
                    icon: PhosphorIconsBold.flag,
                    label: l10n.forumReportPost,
                    isDanger: true,
                    onTap: () => _run(
                      () => openReportFlow(
                        hostContext,
                        iarContext: IarMessageContext(
                          message: firstMessage,
                          guildId: forum.guildId,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            for (final List<Widget> group in threadGroups)
              if (group.isNotEmpty) StarMenuGroup(children: group),
          ],
        ),
      ],
    );
  }
}

Future<void> showForumPostTagsSheet(
  BuildContext context, {
  required Channel forum,
  required Channel post,
  required bool moderator,
}) => StarBottomSheet.show<void>(
  context,
  title: StarLocalizations.of(context).forumEditTags,
  builder: (BuildContext sheetContext, VoidCallback close) =>
      _ForumPostTagsEditor(
        hostContext: context,
        forum: forum,
        post: post,
        moderator: moderator,
        close: close,
      ),
);

class _ForumPostTagsEditor extends ConsumerStatefulWidget {
  const _ForumPostTagsEditor({
    required this.hostContext,
    required this.forum,
    required this.post,
    required this.moderator,
    required this.close,
  });

  final BuildContext hostContext;
  final Channel forum;
  final Channel post;
  final bool moderator;
  final VoidCallback close;

  @override
  ConsumerState<_ForumPostTagsEditor> createState() =>
      _ForumPostTagsEditorState();
}

class _ForumPostTagsEditorState extends ConsumerState<_ForumPostTagsEditor> {
  late List<String> _selected = postAppliedTags(widget.post);
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final bool ok = await updateForumPost(
      widget.hostContext,
      ref,
      widget.post,
      <String, Object?>{'applied_tags': _selected},
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (ok) {
      widget.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final List<ForumTagResponse> tags = <ForumTagResponse>[
      for (final ForumTagResponse tag in forumAvailableTags(widget.forum))
        if (widget.moderator ||
            !tag.moderated ||
            postAppliedTags(widget.post).contains(tag.id))
          tag,
    ];
    final List<String> original = postAppliedTags(widget.post);
    final bool requiresTag = forumRequiresTag(widget.forum);
    final bool changed =
        _selected.length != original.length ||
        !_selected.every(original.contains);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.forumTagsLimitHint(maxAppliedTagsPerPost),
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
          SizedBox(height: context.layout.s3),
          ForumTagSelector(
            tags: tags,
            selected: _selected,
            maxSelected: maxAppliedTagsPerPost,
            onToggle: (String id) => setState(() {
              _selected = _selected.contains(id)
                  ? <String>[
                      for (final String tag in _selected)
                        if (tag != id) tag,
                    ]
                  : <String>[..._selected, id];
            }),
          ),
          SizedBox(height: context.layout.s4),
          StarButton.primary(
            onPressed:
                changed &&
                    !_saving &&
                    (!requiresTag || _selected.isNotEmpty || widget.moderator)
                ? () => unawaited(_save())
                : null,
            isLoading: _saving,
            label: l10n.forumSaveTags,
          ),
        ],
      ),
    );
  }
}
