import 'package:star_app/core/assistant/assistant_command.dart';
import 'package:star_app/features/profile/domain/presence_status_labels.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

String spokenForAssistantGate({
  required AssistantCommandGateSpoken gate,
  required StarLocalizations l10n,
}) {
  return switch (gate) {
    AssistantCommandGateSpoken.needsLogin => l10n.assistantNeedsLogin,
    AssistantCommandGateSpoken.notInVoice => l10n.assistantNotInVoice,
    AssistantCommandGateSpoken.notFound => l10n.assistantNotFound,
    AssistantCommandGateSpoken.dmsDisabled => l10n.assistantDmsDisabled,
    AssistantCommandGateSpoken.failed => l10n.assistantFailed,
  };
}

enum AssistantCommandGateSpoken {
  needsLogin,
  notInVoice,
  notFound,
  dmsDisabled,
  failed,
}

String spokenForAssistantSuccess({
  required AssistantCommand command,
  required StarLocalizations l10n,
  Map<String, Object?> extras = const <String, Object?>{},
}) {
  return switch (command) {
    VoiceSetMuteCommand() =>
      extras['muted'] == true ? l10n.assistantOkMuted : l10n.assistantOkUnmuted,
    VoiceLeaveCommand() => l10n.assistantOkLeftVoice,
    VoiceJoinCommand() => l10n.assistantOkJoinedVoice,
    VoiceStartDmCallCommand() => l10n.assistantOkStartedCall,
    PresenceSetStatusCommand(:final String status) => l10n.assistantOkStatusSet(
      presenceStatusLabel(status, l10n),
    ),
    PresenceSetCustomStatusCommand(:final String text) =>
      text.trim().isEmpty
          ? l10n.assistantOkCustomStatusCleared
          : l10n.assistantOkCustomStatusSet,
    OpenDmsCommand() => l10n.assistantOkOpened,
    SendDmCommand() => l10n.assistantOkMessageSent,
  };
}
