part of 'channel_details_sheet.dart';

class _DetailsIdentityHeader extends ConsumerWidget {
  const _DetailsIdentityHeader({
    required this.channel,
    required this.dm,
    required this.showTopic,
    required this.topicExpanded,
    required this.onToggleTopic,
    required this.onClose,
    this.closeOnLeading = false,
  });

  final Channel? channel;
  final DmConversation? dm;
  final bool showTopic;
  final bool topicExpanded;
  final VoidCallback onToggleTopic;
  final VoidCallback onClose;
  final bool closeOnLeading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Channel? channelEntity = channel;
    final DmConversation? dmConvo = dm;
    final String? friendNickname =
        dmConvo != null && !dmConvo.isGroup && !dmConvo.isPersonalNotes
        ? ref.watch(friendNicknameProvider(dmConvo.recipientId)).value
        : null;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String? currentUserId = ref.watch(currentUserIdProvider);
    final title =
        channelEntity?.name ??
        dmConvo?.displayNameWith(
          friendNickname,
          l10n: l10n,
          currentUserId: currentUserId,
        ) ??
        l10n.channelDetailsFallbackTitle;
    final subtitle = _detailsSubtitle(
      l10n: l10n,
      channel: channelEntity,
      dm: dm,
      uniqueUsernames: ref.watch(uniqueUsernamesProvider),
    );
    final topic = showTopic ? channelEntity?.topic?.trim() : null;
    final bool showUserTag = dm != null && isBotOrSystemDmRecipient(dm!);
    final hasTopic = topic != null && topic.isNotEmpty;
    final int? effectivePermissionBits = channelEntity != null
        ? ref
              .watch(
                effectiveGuildChannelPermissionBitsProvider(channelEntity.id),
              )
              .value
        : null;

    return StarSheetIdentityHeader(
      leading: _DetailsAvatar(channel: channelEntity, dm: dm),
      title: title,
      subtitle: subtitle,
      onClose: onClose,
      closeOnLeading: closeOnLeading,
      hideLeading: closeOnLeading,
      titlePrefix: closeOnLeading
          ? null
          : switch (channelEntity) {
              null => null,
              final Channel c => ChannelIcon(
                type: c.type,
                channel: c,
                effectivePermissionBits: effectivePermissionBits,
                size: 16,
                color: context.colors.textPrimary,
              ),
            },
      titleAdornments: [if (showUserTag) StarUserTag(isSystem: dm!.isSystem)],
      body: hasTopic
          ? _TopicCard(
              topic: topic,
              channelId: channelEntity?.id,
              expanded: topicExpanded,
              onToggle: onToggleTopic,
            )
          : null,
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.channelId,
    required this.expanded,
    required this.onToggle,
  });

  final String topic;
  final String? channelId;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedSize(
            duration: context.motion.fast,
            curve: context.motion.curve,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: expanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 60),
              child: ClipRect(
                child: MessageMarkdown(
                  data: topic,
                  channelId: channelId,
                  markdownContext: StarMarkdownContext.restrictedChannelTopic,
                  baseStyle: context.textStyles.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: PhosphorIcon(
              expanded
                  ? PhosphorIconsBold.caretUp
                  : PhosphorIconsBold.caretDown,
              size: 16,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsAvatar extends ConsumerWidget {
  const _DetailsAvatar({required this.channel, required this.dm});

  static const double _size = 48;

  final Channel? channel;
  final DmConversation? dm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dm = this.dm;
    final channel = this.channel;
    if (dm != null) {
      if (dm.isPersonalNotes) {
        final currentUserId = ref.watch(currentUserIdProvider);
        if (currentUserId == null) {
          return const SizedBox.square(dimension: _size);
        }
        return FutureBuilder<db.User?>(
          future: ref
              .read(starDatabaseProvider)
              .userDao
              .getUserById(currentUserId),
          builder: (context, snapshot) {
            final user = snapshot.data;
            return StarAvatar.userPresence(
              fallbackText:
                  user?.globalName ??
                  user?.username ??
                  StarLocalizations.of(context).channelDetailsMemberYou,
              userId: currentUserId,
              imageUrl: user?.avatar == null
                  ? null
                  : StarMediaUrl.userAvatar(
                      userId: currentUserId,
                      hash: user!.avatar,
                    ),
              avatarColor: user?.avatarColor,
              size: _size,
            );
          },
        );
      }
      if (dm.isGroup) {
        return GroupDmAvatar.conversation(dm, size: _size);
      }
      return StarAvatar.userPresence(
        fallbackText: dm.displayNameWith(
          ref.watch(friendNicknameProvider(dm.recipientId)).value,
        ),
        userId: dm.recipientId,
        imageUrl: StarMediaUrl.userAvatar(
          userId: dm.recipientId,
          hash: dm.recipientAvatar,
        ),
        size: _size,
      );
    }
    if (channel != null) {
      final int? effectivePermissionBits = ref
          .watch(effectiveGuildChannelPermissionBitsProvider(channel.id))
          .value;
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: context.colors.backgroundTertiary,
          borderRadius: BorderRadius.circular(_size / 2),
        ),
        child: Center(
          child: ChannelIcon(
            type: channel.type,
            channel: channel,
            effectivePermissionBits: effectivePermissionBits,
            size: _size * 0.5,
            color: context.colors.textPrimary,
          ),
        ),
      );
    }
    return const SizedBox.square(dimension: _size);
  }
}
