import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/channel_header_icon_button.dart';
import 'package:star_app/features/mature_content/providers/mature_content_agreements_provider.dart';
import 'package:star_app/features/threads/presentation/thread_browser_sheet.dart';
import 'package:star_app/features/threads/presentation/thread_members_sheet.dart';
import 'package:star_app/features/threads/presentation/thread_menu_sheet.dart';
import 'package:star_app/features/threads/providers/thread_ui_providers.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

bool showsThreadHeaderActions(Channel? channel) =>
    channel != null &&
    (isTextThreadParentType(channel.type) || channel.isThread);

class ThreadHeaderMobileButton extends ConsumerWidget {
  const ThreadHeaderMobileButton({required this.channel, super.key});

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showsThreadHeaderActions(channel) ||
        watchMatureContentGateUp(ref, channel.id)) {
      return const SizedBox.shrink();
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isThread = channel.isThread;
    return StarButton.circle(
      icon: isThread ? PhosphorIconsFill.users : PhosphorIconsFill.chatsCircle,
      variant: StarButtonVariant.secondary,
      size: StarButtonSize.small,
      iconSize: 20,
      semanticLabel: isThread ? l10n.threadMembers : l10n.threadBrowserTitle,
      onPressed: () => unawaited(
        isThread
            ? showThreadMembersSheet(context, channel)
            : showThreadBrowserSheet(context, ref, channel),
      ),
    );
  }
}

class ThreadHeaderToolbarButtons extends ConsumerWidget {
  const ThreadHeaderToolbarButtons({required this.channel, super.key});

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showsThreadHeaderActions(channel) ||
        watchMatureContentGateUp(ref, channel.id)) {
      return const SizedBox.shrink();
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    if (!channel.isThread) {
      return ChannelHeaderIconButton(
        icon: PhosphorIconsFill.chatsCircle,
        label: l10n.threadBrowserTitle,
        onPressed: () =>
            unawaited(showThreadBrowserSheet(context, ref, channel)),
      );
    }
    final bool isMember =
        ref.watch(threadMembershipProvider(channel.id)).value != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (isMember)
          ChannelHeaderIconButton(
            icon: PhosphorIconsFill.bell,
            label: l10n.threadNotificationSettings,
            onPressed: () =>
                unawaited(showThreadNotificationSheet(context, ref, channel)),
          ),
        ChannelHeaderIconButton(
          icon: PhosphorIconsFill.dotsThreeCircle,
          label: l10n.threadMoreOptions,
          onPressed: () =>
              unawaited(showThreadMenuSheet(context, ref, channel)),
        ),
      ],
    );
  }
}
