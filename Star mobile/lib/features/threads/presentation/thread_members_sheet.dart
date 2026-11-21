import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/permissions/thread_permissions.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/profile/presentation/user_profile_sheet.dart';
import 'package:star_app/features/threads/data/threads_repository.dart';
import 'package:star_app/features/threads/providers/thread_member_list_provider.dart';
import 'package:star_app/features/threads/providers/thread_ui_providers.dart';
import 'package:star_app/features/threads/utils/thread_actions.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/export.dart' hide ChannelType;
import 'package:star_dart/gateway.dart';

Future<void> showThreadMembersSheet(BuildContext context, Channel thread) {
  return StarBottomSheet.showScrollable<void>(
    context,
    title: StarLocalizations.of(context).threadMembers,
    desktop: const StarDesktopPresentation(
      surface: StarDesktopSurface.popout,
      placement: StarDesktopPlacement.belowEnd,
    ),
    initialChildSize: StarBottomSheet.scrollableSheetHalfSize,
    builder: (sheetContext, scrollController, close) => ThreadMembersList(
      thread: thread,
      scrollController: scrollController,
      hostContext: context,
    ),
  );
}

String threadMemberDisplayName(ThreadMemberEntry entry) {
  final GuildMemberResponse? member = entry.member;
  final String? nick = member?.nick;
  if (nick != null && nick.isNotEmpty) {
    return nick;
  }
  final String? globalName = member?.user.globalName;
  if (globalName != null && globalName.isNotEmpty) {
    return globalName;
  }
  return member?.user.username ?? entry.userId;
}

class ThreadMembersPanel extends ConsumerWidget {
  const ThreadMembersPanel({required this.thread, super.key});

  static const double width = 240;

  final Channel thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: width,
      color: context.colors.backgroundSecondary,
      child: ThreadMembersList(thread: thread, hostContext: context),
    );
  }
}

class ThreadMembersList extends ConsumerWidget {
  const ThreadMembersList({
    required this.thread,
    required this.hostContext,
    this.scrollController,
    super.key,
  });

  final Channel thread;
  final BuildContext hostContext;
  final ScrollController? scrollController;

  Future<void> _remove(WidgetRef ref, ThreadMemberEntry entry) async {
    await runThreadAction(
      hostContext,
      ref,
      (ThreadsRepository repo) => repo.removeMember(
        guildId: thread.guildId,
        threadId: thread.id,
        userId: entry.userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    ref.watch(threadMemberListSubscriptionProvider(thread.guildId, thread.id));
    final List<ThreadMemberEntry>? members = ref.watch(
      threadMemberListProvider(thread.id),
    );
    final ThreadActorContext? actor = ref.watch(
      threadActorContextProvider(thread.id),
    );
    final String? currentUserId = ref.watch(currentUserIdProvider);
    final bool canRemove =
        actor != null && canRemoveThreadMember(actor) == null;
    if (members == null) {
      return const Center(child: StarLoadingSpinner());
    }
    if (members.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.layout.s4),
          child: Text(
            l10n.threadMembersEmpty,
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textPrimaryMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      controller: scrollController,
      padding: StarBottomSheet.scrollViewPadding(
        context,
        padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
      ),
      children: <Widget>[
        StarListSection(
          header: l10n.threadMembersCount(members.length),
          children: <Widget>[
            for (final ThreadMemberEntry entry in members)
              _memberRow(
                context,
                ref,
                entry,
                removable: canRemove && entry.userId != currentUserId,
              ),
          ],
        ),
      ],
    );
  }

  Widget _memberRow(
    BuildContext context,
    WidgetRef ref,
    ThreadMemberEntry entry, {
    required bool removable,
  }) {
    final String name = threadMemberDisplayName(entry);
    return StarListRow(
      leading: StarAvatar.user(
        userId: entry.userId,
        imageUrl: StarMediaUrl.userAvatar(
          userId: entry.userId,
          hash: entry.member?.user.avatar,
        ),
        fallbackText: name,
        avatarColor: entry.member?.user.avatarColor,
        size: 36,
        showStatus: false,
      ),
      title: name,
      trailing: removable
          ? StarButton.ghost(
              icon: PhosphorIconsBold.userMinus,
              isSquare: true,
              size: StarButtonSize.compact,
              semanticLabel: StarLocalizations.of(
                context,
              ).threadRemoveMember(name),
              onPressedAsync: () => _remove(ref, entry),
            )
          : null,
      onTap: () => unawaited(
        StarUserProfileSheet.show(
          hostContext,
          userId: entry.userId,
          guildId: thread.guildId,
        ),
      ),
    );
  }
}
