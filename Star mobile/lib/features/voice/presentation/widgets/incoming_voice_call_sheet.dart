import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/providers/channel_providers.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/presentation/widgets/group_dm_avatar.dart';
import 'package:star_app/features/dm/providers/dm_view_model.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/voice/presentation/widgets/incoming_voice_call_desktop_card.dart';
import 'package:star_app/features/voice/providers/pending_incoming_voice_calls_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_app/shared/utils/chat_context_utils.dart';

const String kIncomingVoiceResultAccept = 'accept';
const String kIncomingVoiceResultReject = 'reject';
const String kIncomingVoiceResultIgnore = 'ignore';
const String kIncomingVoiceResultRemoteDismiss = 'remote_dismiss';

String _resolveSheetHeaderTitle({
  required DmConversation? dm,
  required Channel? guildChannel,
  required String channelId,
  required StarLocalizations l10n,
}) {
  if (guildChannel != null) {
    final String name = guildChannel.name;
    return name.isNotEmpty ? name : l10n.incomingVoiceCallTitle;
  }
  if (dm != null) {
    return dmConversationDisplayName(l10n, dm);
  }
  return l10n.incomingVoiceCallTitle;
}

Future<String?> showIncomingVoiceCallSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String channelId,
}) {
  final List<DmConversation> conversations = ref.read(
    dmViewModelProvider.select((DmViewState s) => s.conversations),
  );
  final DmConversation? dm = findDmById(conversations, channelId);
  final AsyncValue<Channel?> channelAsync = ref.read(
    channelByIdProvider(channelId),
  );
  final Channel? guildChannel = switch (channelAsync) {
    AsyncData(:final value) => value,
    _ => null,
  };
  final StarLocalizations l10n = StarLocalizations.of(context);
  final String headerTitle = _resolveSheetHeaderTitle(
    dm: dm,
    guildChannel: guildChannel,
    channelId: channelId,
    l10n: l10n,
  );
  if (usesDesktopPointerUi(context)) {
    return _showDesktopCard(
      context,
      ref: ref,
      channelId: channelId,
      dm: dm,
      callerName: headerTitle,
    );
  }
  return StarBottomSheet.showScrollable<String>(
    context,
    useRootNavigator: true,
    title: headerTitle,
    isDismissible: false,
    initialChildSize: StarBottomSheet.scrollableSheetHalfSize,
    minChildSize: 0.28,
    builder: (BuildContext sheetContext, ScrollController scrollController, _) {
      return _IncomingVoiceCallSheetBody(
        sheetContext: sheetContext,
        scrollController: scrollController,
        channelId: channelId,
      );
    },
  );
}

Future<String?> _showDesktopCard(
  BuildContext context, {
  required WidgetRef ref,
  required String channelId,
  required DmConversation? dm,
  required String callerName,
}) async {
  final StreamController<void> dismissals = StreamController<void>();
  final ProviderSubscription<List<String>> subscription = ref.listenManual(
    pendingIncomingVoiceChannelIdsProvider,
    (List<String>? _, List<String> next) {
      if (!next.contains(channelId)) {
        dismissals.add(null);
      }
    },
  );
  try {
    return await showIncomingVoiceCallDesktopCard(
      context,
      callerName: callerName,
      avatar: _incomingCallAvatar(context, dm: dm),
      remoteDismiss: dismissals.stream,
      remoteDismissResult: kIncomingVoiceResultRemoteDismiss,
    );
  } finally {
    subscription.close();
    await dismissals.close();
  }
}

Widget _incomingCallAvatar(
  BuildContext context, {
  required DmConversation? dm,
}) {
  const double size = 80;
  if (dm != null && dm.isGroup) {
    return GroupDmAvatar.conversation(dm, size: size);
  }
  if (dm != null) {
    return StarAvatar.userPresence(
      fallbackText: dm.recipientName,
      userId: dm.recipientId,
      imageUrl: StarMediaUrl.userAvatar(
        userId: dm.recipientId,
        hash: dm.recipientAvatar,
      ),
      size: size,
    );
  }
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.colors.backgroundTertiary,
    ),
    child: Center(
      child: PhosphorIcon(
        PhosphorIconsFill.phone,
        size: 36,
        color: context.colors.textSecondary,
      ),
    ),
  );
}

class _IncomingVoiceCallSheetBody extends ConsumerStatefulWidget {
  const _IncomingVoiceCallSheetBody({
    required this.sheetContext,
    required this.scrollController,
    required this.channelId,
  });

  final BuildContext sheetContext;
  final ScrollController scrollController;
  final String channelId;

  @override
  ConsumerState<_IncomingVoiceCallSheetBody> createState() =>
      _IncomingVoiceCallSheetBodyState();
}

class _IncomingVoiceCallSheetBodyState
    extends ConsumerState<_IncomingVoiceCallSheetBody> {
  bool _hasPopped = false;

  void _pop(String value) {
    if (_hasPopped || !widget.sheetContext.mounted) {
      return;
    }
    final NavigatorState navigator = Navigator.of(
      widget.sheetContext,
      rootNavigator: true,
    );
    if (!navigator.canPop()) {
      return;
    }
    _hasPopped = true;
    navigator.pop<String>(value);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<String>>(pendingIncomingVoiceChannelIdsProvider, (
      List<String>? _,
      List<String> next,
    ) {
      if (!next.contains(widget.channelId)) {
        _pop(kIncomingVoiceResultRemoteDismiss);
      }
    });
    final StarLocalizations l10n = StarLocalizations.of(context);
    final List<DmConversation> conversations = ref.watch(
      dmViewModelProvider.select((DmViewState s) => s.conversations),
    );
    final DmConversation? dm = findDmById(conversations, widget.channelId);
    final AsyncValue<Channel?> channelWatch = ref.watch(
      channelByIdProvider(widget.channelId),
    );
    final Channel? guildChannel = switch (channelWatch) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final String centeredName = _resolveSheetHeaderTitle(
      dm: dm,
      guildChannel: guildChannel,
      channelId: widget.channelId,
      l10n: l10n,
    );
    final layout = context.layout;
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: StarBottomSheet.scrollViewPadding(
        context,
        padding: EdgeInsets.symmetric(horizontal: layout.s4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              PhosphorIcon(
                PhosphorIconsBold.phoneIncoming,
                size: 18,
                color: context.colors.textSecondary,
              ),
              SizedBox(width: layout.s2),
              Text(
                l10n.incomingVoiceCallLabel,
                style: context.textStyles.categoryName.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: layout.s4),
          Center(child: _incomingCallAvatar(context, dm: dm)),
          SizedBox(height: layout.s3),
          Text(
            centeredName,
            textAlign: TextAlign.center,
            style: context.textStyles.channelName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: layout.s4),
          FilledButton.icon(
            onPressed: () => _pop(kIncomingVoiceResultAccept),
            icon: PhosphorIcon(
              PhosphorIconsFill.phone,
              size: 18,
              color: context.colors.textPrimary,
            ),
            label: Text(l10n.incomingVoiceCallAccept),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          SizedBox(height: layout.s3),
          FilledButton.icon(
            onPressed: () => _pop(kIncomingVoiceResultReject),
            icon: PhosphorIcon(
              PhosphorIconsBold.x,
              size: 18,
              color: context.colors.buttonDangerText,
            ),
            label: Text(l10n.incomingVoiceCallDecline),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: context.colors.buttonDangerFill,
              foregroundColor: context.colors.buttonDangerText,
            ),
          ),
          SizedBox(height: layout.s3),
          OutlinedButton(
            onPressed: () => _pop(kIncomingVoiceResultIgnore),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(l10n.incomingVoiceCallIgnore),
          ),
        ],
      ),
    );
  }
}
