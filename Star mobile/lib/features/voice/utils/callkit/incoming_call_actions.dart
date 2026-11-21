import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/api_exception.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/database/star_database.dart' as db;
import 'package:star_app/core/experiments/experiments_provider.dart';
import 'package:star_app/core/gateway/providers/gateway_event_providers.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/router/navigate_to_content.dart';
import 'package:star_app/core/router/route_names.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/mature_content/utils/channel_gate_navigator.dart';
import 'package:star_app/features/settings/providers/preferences/voice_prompts_preferences_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/presentation/sheets/voice_p2p_sheets.dart';
import 'package:star_app/features/voice/providers/voice_p2p_mode_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_state.dart';
import 'package:star_app/features/voice/utils/connection/connection_actions.dart';
import 'package:star_app/features/voice/utils/e2ee/p2p_mode.dart';
import 'package:star_app/features/voice/voice_session_errors.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart' hide ChannelType;
import 'package:go_router/go_router.dart';

const Duration _kHeadlessP2pConsentTimeout = Duration(seconds: 20);
const Duration _kHeadlessP2pConsentContextPollInterval = Duration(
  milliseconds: 200,
);

void _showIncomingVoiceJoinErrorToast(
  ProviderContainer container,
  StarLocalizations l10n,
) {
  final String? errorMessage = container
      .read(voiceSessionProvider)
      .errorMessage;
  final String message = errorMessage == null
      ? l10n.voiceJoinIncomingCallFailed
      : resolveVoiceSessionErrorMessage(errorMessage, l10n);
  container
      .read(toastProvider.notifier)
      .show(StarToast(message: message, variant: StarToastVariant.danger));
}

void _openChannelForVoiceGate(
  BuildContext? ctx, {
  required String? guildId,
  required String channelId,
}) {
  if (ctx == null || !ctx.mounted) {
    return;
  }
  if (guildId != null && guildId.isNotEmpty) {
    navigateToContent(ctx, RoutePaths.guildChannel(guildId, channelId));
    return;
  }
  unawaited(ctx.push(RoutePaths.dmChannelCall(channelId)));
}

Future<void> executeAcceptIncomingVoiceCall(
  WidgetRef ref,
  BuildContext ctx,
  String channelId,
) async {
  final StarLocalizations l10n = StarLocalizations.of(ctx);
  final String? uid = ref.read(currentUserIdProvider);
  if (uid != null) {
    ref
        .read(activeCallsProvider(readAccountUserId(ref)).notifier)
        .removeUserFromPendingRing(channelId: channelId, userId: uid);
  }
  if (!ctx.mounted) {
    return;
  }
  final db.StarDatabase database = ref.read(starDatabaseProvider);
  final db.Channel? channelRow = await database.channelDao.getChannelById(
    channelId,
  );
  final String? guildIdForJoin = channelRow?.guildId;
  final Channel? channel = channelRow == null
      ? null
      : Channel.fromRow(channelRow);
  if (!ctx.mounted) {
    return;
  }
  try {
    final VoiceJoinResult result = await joinVoiceChannelWithConfirmation(
      ref: ref,
      context: ctx,
      guildId: guildIdForJoin,
      channelId: channelId,
      channel: channel,
    );
    if (result == VoiceJoinResult.failed) {
      _showIncomingVoiceJoinErrorToast(ref.container, l10n);
      return;
    }
    if (result == VoiceJoinResult.cancelled) {
      return;
    }
    if (result == VoiceJoinResult.gated ||
        guildIdForJoin == null ||
        guildIdForJoin.isEmpty) {
      if (!ctx.mounted) {
        return;
      }
      _openChannelForVoiceGate(
        ctx,
        guildId: guildIdForJoin,
        channelId: channelId,
      );
    }
  } on Object {
    _showIncomingVoiceJoinErrorToast(ref.container, l10n);
  }
}

Future<void> executeDeclineIncomingVoiceCall(
  WidgetRef ref,
  BuildContext ctx,
  String channelId,
) async {
  final StarLocalizations l10n = StarLocalizations.of(ctx);
  final VoiceSessionState voice = ref.read(voiceSessionProvider);
  ref
      .read(activeCallsProvider(readAccountUserId(ref)).notifier)
      .clearPendingRingForChannel(channelId);
  if (voice.channelId == channelId && voice.isInVoice) {
    await ref.read(voiceSessionProvider.notifier).leaveVoice(endCall: false);
  }
  try {
    final StarClient client = ref.read(starClientProvider);
    await client.channels.stopRingingCallRecipients(
      channelId: channelId,
      body: const CallRingBodySchema(),
    );
  } on Object catch (error) {
    _handleStopRingingFailure(ctx.mounted ? ctx : null, l10n, error);
  }
}

Future<void> executeIgnoreIncomingVoiceCall(
  WidgetRef ref,
  BuildContext ctx,
  String channelId,
) async {
  final StarLocalizations l10n = StarLocalizations.of(ctx);
  final String? uid = ref.read(currentUserIdProvider);
  if (uid == null) {
    return;
  }
  ref
      .read(activeCallsProvider(readAccountUserId(ref)).notifier)
      .removeUserFromPendingRing(channelId: channelId, userId: uid);
  try {
    final StarClient client = ref.read(starClientProvider);
    await client.channels.stopRingingCallRecipients(
      channelId: channelId,
      body: CallRingBodySchema(recipients: [uid]),
    );
  } on Object catch (error) {
    _handleStopRingingFailure(ctx.mounted ? ctx : null, l10n, error);
  }
}

Future<void> executeAcceptIncomingVoiceCallFromCallKit(
  Ref ref,
  String channelId, {
  String? guildId,
}) async {
  try {
    await executeAcceptIncomingVoiceCallCore(
      ref,
      channelId,
      guildId: guildId,
      answeredFromSystemCallUi: true,
    );
  } on Object {
    final BuildContext? ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return;
    }
    _showIncomingVoiceJoinErrorToast(
      ref.container,
      StarLocalizations.of(ctx),
    );
  }
}

Future<void> executeDeclineIncomingVoiceCallFromCallKit(
  Ref ref,
  String channelId,
) async {
  await executeDeclineIncomingVoiceCallCore(ref, channelId);
  try {
    final StarClient client = ref.read(starClientProvider);
    await client.channels.stopRingingCallRecipients(
      channelId: channelId,
      body: const CallRingBodySchema(),
    );
  } on Object catch (error) {
    final BuildContext? ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return;
    }
    _handleStopRingingFailure(ctx, StarLocalizations.of(ctx), error);
  }
}

Future<void> executeIgnoreIncomingVoiceCallFromCallKit(
  Ref ref,
  String channelId,
) async {
  try {
    await executeIgnoreIncomingVoiceCallCore(ref, channelId);
  } on Object catch (error) {
    final BuildContext? ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return;
    }
    _handleStopRingingFailure(ctx, StarLocalizations.of(ctx), error);
  }
}

Future<BuildContext?> _waitForForegroundNavigatorContext(
  Ref ref,
  DateTime deadline,
) async {
  while (true) {
    final BuildContext? ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted && ref.read(appUiForegroundProvider)) {
      return ctx;
    }
    if (!DateTime.now().isBefore(deadline)) {
      return null;
    }
    await Future<void>.delayed(_kHeadlessP2pConsentContextPollInterval);
  }
}

bool shouldTreatSystemCallAnswerAsP2pConsent({
  required bool answeredFromSystemCallUi,
  required bool isForeground,
}) {
  return answeredFromSystemCallUi && !isForeground;
}

Future<bool?> _resolveHeadlessJoinP2p(
  Ref ref, {
  required String? guildId,
  required String channelId,
  required Channel? channel,
  bool answeredFromSystemCallUi = false,
}) async {
  final VoiceChannelMode mode = ref.read(
    voiceChannelModeForProvider(guildId: guildId, channelId: channelId),
  );
  final bool pinned = channel?.rtcP2p ?? false;
  if (mode != VoiceChannelMode.p2p &&
      !(mode == VoiceChannelMode.empty &&
          pinned &&
          ref.read(voiceP2pEnabledProvider))) {
    return false;
  }
  if (ref.read(voicePromptsPreferencesProvider).skipP2pJoinConfirm) {
    return true;
  }
  if (shouldTreatSystemCallAnswerAsP2pConsent(
    answeredFromSystemCallUi: answeredFromSystemCallUi,
    isForeground: ref.read(appUiForegroundProvider),
  )) {
    return true;
  }
  final DateTime deadline = DateTime.now().add(_kHeadlessP2pConsentTimeout);
  final BuildContext? ctx = await _waitForForegroundNavigatorContext(
    ref,
    deadline,
  );
  if (ctx == null || !ctx.mounted) {
    return null;
  }
  final bool agreed = await showVoiceP2pConsentSheet(
    ctx,
    pinned: pinned,
    timeout: deadline.difference(DateTime.now()),
  );
  return agreed ? true : null;
}

Future<void> executeAcceptIncomingVoiceCallCore(
  Ref ref,
  String channelId, {
  String? guildId,
  bool answeredFromSystemCallUi = false,
}) async {
  final String? uid = ref.read(currentUserIdProvider);
  if (uid != null) {
    ref
        .read(activeCallsProvider(readAccountUserId(ref)).notifier)
        .removeUserFromPendingRing(channelId: channelId, userId: uid);
  }
  final db.StarDatabase database = ref.read(starDatabaseProvider);
  final db.Channel? channelRow = await database.channelDao.getChannelById(
    channelId,
  );
  final String? fallbackGuildId = guildId == null || guildId.isEmpty
      ? null
      : guildId;
  final String? guildIdForJoin = channelRow?.guildId ?? fallbackGuildId;
  final Channel? channel = channelRow == null
      ? null
      : Channel.fromRow(channelRow);
  final bool? p2p = await _resolveHeadlessJoinP2p(
    ref,
    guildId: guildIdForJoin,
    channelId: channelId,
    channel: channel,
    answeredFromSystemCallUi: answeredFromSystemCallUi,
  );
  if (p2p == null) {
    return;
  }
  final bool joined = await ref
      .read(voiceSessionProvider.notifier)
      .connectToVoiceChannel(
        guildId: guildIdForJoin,
        channelId: channelId,
        p2p: p2p,
      );
  if (joined) {
    return;
  }
  if (!await isChannelGateBlocking(
    container: ref.container,
    channelId: channelId,
    channel: channel,
  )) {
    return;
  }
  _openChannelForVoiceGate(
    rootNavigatorKey.currentContext,
    guildId: guildIdForJoin,
    channelId: channelId,
  );
}

Future<void> executeDeclineIncomingVoiceCallCore(
  Ref ref,
  String channelId,
) async {
  final VoiceSessionState voice = ref.read(voiceSessionProvider);
  ref
      .read(activeCallsProvider(readAccountUserId(ref)).notifier)
      .clearPendingRingForChannel(channelId);
  if (voice.channelId == channelId && voice.isInVoice) {
    await ref.read(voiceSessionProvider.notifier).leaveVoice(endCall: false);
  }
}

Future<void> executeIgnoreIncomingVoiceCallCore(
  Ref ref,
  String channelId,
) async {
  final String? uid = ref.read(currentUserIdProvider);
  if (uid == null) {
    return;
  }
  ref
      .read(activeCallsProvider(readAccountUserId(ref)).notifier)
      .removeUserFromPendingRing(channelId: channelId, userId: uid);
  final StarClient client = ref.read(starClientProvider);
  await client.channels.stopRingingCallRecipients(
    channelId: channelId,
    body: CallRingBodySchema(recipients: [uid]),
  );
}

bool _isBenignStopRingingError(Object error) {
  final String? code = ApiException.from(error).code;
  return code == 'NO_ACTIVE_CALL' || code == 'UNKNOWN_CHANNEL';
}

void _handleStopRingingFailure(
  BuildContext? ctx,
  StarLocalizations l10n,
  Object error,
) {
  if (_isBenignStopRingingError(error)) {
    talker.warning('[Voice] stop ringing: $error');
    return;
  }
  if (ctx == null || !ctx.mounted) {
    return;
  }
  _showRingingUpdateFailed(ctx, l10n);
}

void _showRingingUpdateFailed(BuildContext context, StarLocalizations l10n) {
  ProviderScope.containerOf(context, listen: false)
      .read(toastProvider.notifier)
      .show(
        StarToast(
          message: l10n.incomingVoiceRingingUpdateFailed,
          variant: StarToastVariant.danger,
        ),
      );
}
