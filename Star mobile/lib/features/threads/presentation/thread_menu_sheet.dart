import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/permissions/thread_permissions.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/providers/channel_providers.dart';
import 'package:star_app/features/channels/providers/unread_provider.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/threads/domain/thread_channel.dart';
import 'package:star_app/features/threads/presentation/thread_members_sheet.dart';
import 'package:star_app/features/threads/presentation/thread_settings_sheet.dart';
import 'package:star_app/features/threads/providers/thread_ui_providers.dart';
import 'package:star_app/features/threads/utils/thread_actions.dart';
import 'package:star_app/features/threads/utils/thread_title.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

Future<void> showThreadMenuSheet(
  BuildContext context,
  WidgetRef hostRef,
  Channel thread,
) {
  return StarBottomSheet.show<void>(
    context,
    title: readThreadTitleText(
      hostRef,
      thread,
      StarLocalizations.of(context),
    ),
    variant: StarBottomSheetVariant.menu,
    builder: (sheetContext, close) => _ThreadMenuBody(
      threadId: thread.id,
      hostContext: context,
      hostRef: hostRef,
      close: close,
    ),
  );
}

Future<void> showThreadNotificationSheet(
  BuildContext context,
  WidgetRef hostRef,
  Channel thread,
) {
  return StarBottomSheet.show<void>(
    context,
    title: StarLocalizations.of(context).threadNotificationSettings,
    variant: StarBottomSheetVariant.menu,
    builder: (sheetContext, close) => _ThreadNotificationBody(
      threadId: thread.id,
      hostContext: context,
      hostRef: hostRef,
      close: close,
    ),
  );
}

class _ThreadMenuBody extends ConsumerWidget {
  const _ThreadMenuBody({
    required this.threadId,
    required this.hostContext,
    required this.hostRef,
    required this.close,
  });

  final String threadId;
  final BuildContext hostContext;
  final WidgetRef hostRef;
  final VoidCallback close;

  void _run(Future<void> Function() action) {
    close();
    unawaited(action());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Channel? thread = ref.watch(channelByIdProvider(threadId)).value;
    if (thread == null) {
      return const SizedBox.shrink();
    }
    final List<List<Widget>> groups = buildThreadMenuGroups(
      context: context,
      ref: ref,
      thread: thread,
      hostContext: hostContext,
      hostRef: hostRef,
      run: _run,
    );
    return StarBottomSheetContent(
      child: StarBottomSheetGroupColumn(
        children: <Widget>[
          for (final List<Widget> group in groups)
            if (group.isNotEmpty) StarMenuGroup(children: group),
        ],
      ),
    );
  }
}

List<List<Widget>> buildThreadMenuGroups({
  required BuildContext context,
  required WidgetRef ref,
  required Channel thread,
  required BuildContext hostContext,
  required WidgetRef hostRef,
  required void Function(Future<void> Function() action) run,
  bool includeMarkRead = true,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final ThreadActorContext? actor = ref.watch(
    threadActorContextProvider(thread.id),
  );
  final ThreadMembership? member = ref
      .watch(threadMembershipProvider(thread.id))
      .value;
  final bool hasUnread =
      ref.watch(channelUnreadProvider(thread.id)).value?.hasUnread ?? false;
  final bool developerMode = ref.watch(
    userSettingsViewModelProvider.select((s) => s.developerMode),
  );
  final bool isModerator = actor != null && isThreadModeratorFor(actor);
  final bool canJoin =
      member == null && actor != null && canJoinThread(actor) == null;
  final bool canLeave = actor != null && canLeaveThread(actor) == null;
  final bool canEdit =
      actor != null &&
      threadPatchRequirement(
            const ThreadPatch(name: true),
            thread.flags ?? 0,
            actor,
          ) ==
          null;
  final bool canArchive =
      actor != null &&
      !thread.isArchivedThread &&
      threadPatchRequirement(
            const ThreadPatch(archived: true),
            thread.flags ?? 0,
            actor,
          ) ==
          null;
  final bool canUnarchiveIt =
      actor != null && thread.isArchivedThread && canUnarchive(actor) == null;
  final bool canDelete = actor != null && canDeleteThread(actor) == null;

  final List<Widget> readGroup = <Widget>[
    if (includeMarkRead && hasUnread)
      StarBottomSheetMenuItem(
        icon: PhosphorIconsFill.checkCircle,
        label: l10n.threadMarkAsRead,
        onTap: () => run(() => markThreadRead(hostRef, thread)),
      ),
    if (member != null) ...<Widget>[
      StarBottomSheetSubmenuItem(
        label: l10n.threadNotificationSettings,
        icon: PhosphorIconsFill.bell,
        onTap: () => run(
          () => showThreadNotificationSheet(hostContext, hostRef, thread),
        ),
      ),
      if (member.muted)
        StarBottomSheetMenuItem(
          icon: PhosphorIconsFill.bellSlash,
          label: l10n.threadUnmute,
          onTap: () => run(() => unmuteThread(hostContext, hostRef, thread)),
        )
      else
        StarBottomSheetSubmenuItem(
          label: l10n.threadMute,
          icon: PhosphorIconsFill.bellSlash,
          onTap: () =>
              run(() => muteThreadWithDuration(hostContext, hostRef, thread)),
        ),
    ],
  ];
  final List<Widget> memberGroup = <Widget>[
    if (canJoin)
      StarBottomSheetMenuItem(
        icon: PhosphorIconsFill.signIn,
        label: l10n.threadJoin,
        onTap: () => run(() => joinThread(hostContext, hostRef, thread)),
      ),
    if (canLeave)
      StarBottomSheetMenuItem(
        icon: PhosphorIconsFill.signOut,
        label: l10n.threadLeave,
        onTap: () => run(() => leaveThread(hostContext, hostRef, thread)),
      ),
    StarBottomSheetMenuItem(
      icon: PhosphorIconsFill.users,
      label: l10n.threadMembers,
      onTap: () => run(() => showThreadMembersSheet(hostContext, thread)),
    ),
    if (canEdit)
      StarBottomSheetMenuItem(
        icon: PhosphorIconsFill.gear,
        label: l10n.threadSettings,
        onTap: () => run(() => showThreadSettingsSheet(hostContext, thread)),
      ),
  ];
  final List<Widget> moderationGroup = <Widget>[
    if (canArchive)
      StarBottomSheetMenuItem(
        icon: PhosphorIconsFill.archive,
        label: l10n.threadArchive,
        onTap: () => run(
          () => setThreadArchived(hostContext, hostRef, thread, archived: true),
        ),
      ),
    if (canUnarchiveIt)
      StarBottomSheetMenuItem(
        icon: PhosphorIconsFill.arrowCounterClockwise,
        label: l10n.threadUnarchive,
        onTap: () => run(
          () =>
              setThreadArchived(hostContext, hostRef, thread, archived: false),
        ),
      ),
    if (isModerator)
      StarBottomSheetMenuItem(
        icon: thread.isLockedThread
            ? PhosphorIconsFill.lockOpen
            : PhosphorIconsFill.lock,
        label: thread.isLockedThread ? l10n.threadUnlock : l10n.threadLock,
        onTap: () => run(
          () => setThreadLocked(
            hostContext,
            hostRef,
            thread,
            locked: !thread.isLockedThread,
          ),
        ),
      ),
    if (canDelete)
      StarBottomSheetMenuItem(
        icon: PhosphorIconsFill.trash,
        label: l10n.threadDelete,
        isDanger: true,
        onTap: () =>
            run(() => confirmDeleteThread(hostContext, hostRef, thread)),
      ),
  ];
  final List<Widget> copyGroup = <Widget>[
    StarBottomSheetMenuItem(
      icon: PhosphorIconsBold.link,
      label: l10n.threadCopyLink,
      onTap: () => run(() => copyThreadLink(hostContext, thread)),
    ),
    if (developerMode)
      StarBottomSheetMenuItem(
        icon: PhosphorIconsBold.identificationCard,
        label: l10n.threadCopyId,
        onTap: () => run(() => copyThreadId(hostContext, thread)),
      ),
  ];
  return <List<Widget>>[readGroup, memberGroup, moderationGroup, copyGroup];
}

class _ThreadNotificationBody extends ConsumerWidget {
  const _ThreadNotificationBody({
    required this.threadId,
    required this.hostContext,
    required this.hostRef,
    required this.close,
  });

  final String threadId;
  final BuildContext hostContext;
  final WidgetRef hostRef;
  final VoidCallback close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final Channel? thread = ref.watch(channelByIdProvider(threadId)).value;
    final ThreadMembership? member = ref
        .watch(threadMembershipProvider(threadId))
        .value;
    if (thread == null || member == null) {
      return const SizedBox.shrink();
    }
    final ThreadNotificationSetting selected = threadNotificationSettingOf(
      member.flags,
    );
    Widget option(ThreadNotificationSetting setting, String label) {
      return StarBottomSheetMenuRadioItem(
        label: label,
        isSelected: selected == setting,
        onTap: () {
          close();
          unawaited(
            setThreadNotificationSetting(
              hostContext,
              hostRef,
              thread,
              currentFlags: member.flags,
              setting: setting,
            ),
          );
        },
      );
    }

    return StarBottomSheetContent(
      child: StarBottomSheetGroupColumn(
        children: <Widget>[
          StarMenuGroup(
            children: <Widget>[
              option(
                ThreadNotificationSetting.parentDefault,
                l10n.threadNotificationParentDefault,
              ),
            ],
          ),
          StarMenuGroup(
            children: <Widget>[
              option(
                ThreadNotificationSetting.allMessages,
                l10n.notificationAllMessages,
              ),
              option(
                ThreadNotificationSetting.onlyMentions,
                l10n.notificationOnlyAtMentions,
              ),
              option(ThreadNotificationSetting.none, l10n.notificationNothing),
            ],
          ),
        ],
      ),
    );
  }
}
