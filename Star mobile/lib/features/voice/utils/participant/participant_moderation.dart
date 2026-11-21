import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_dart/export.dart';

Future<void> runVoiceParticipantModeration(
  WidgetRef ref, {
  required String actionLabel,
  required Future<void> Function() action,
}) async {
  try {
    await action();
  } on Object catch (error, stackTrace) {
    talker.error(
      '[VoiceParticipantModeration] action failed: $error',
      error,
      stackTrace,
    );
    await showApiErrorFromRoot(
      ApiErrorAction.moderateVoiceMember,
      error,
      details: ApiErrorDetails(subject: actionLabel),
    );
  }
}

GuildMemberUpdateRequest _memberVoiceUpdate({bool? mute, bool? deaf}) {
  return GuildMemberUpdateRequest(mute: mute, deaf: deaf);
}

Future<void> _updateGuildMemberVoiceState({
  required WidgetRef ref,
  required String guildId,
  required String userId,
  required String actionLabel,
  required GuildMemberUpdateRequest body,
}) {
  return runVoiceParticipantModeration(
    ref,
    actionLabel: actionLabel,
    action: () => ref
        .read(starClientProvider)
        .guilds
        .updateGuildMember(guildId: guildId, userId: userId, body: body),
  );
}

Map<String, dynamic> buildDisconnectVoiceParticipantBody({
  String? connectionId,
}) {
  return <String, dynamic>{'channel_id': null, 'connection_id': ?connectionId};
}

Future<void> updateVoiceParticipantCommunityMute({
  required WidgetRef ref,
  required String guildId,
  required String userId,
  required bool muted,
  required String actionLabel,
}) {
  return _updateGuildMemberVoiceState(
    ref: ref,
    guildId: guildId,
    userId: userId,
    actionLabel: actionLabel,
    body: _memberVoiceUpdate(mute: muted),
  );
}

Future<void> updateVoiceParticipantCommunityDeafen({
  required WidgetRef ref,
  required String guildId,
  required String userId,
  required bool deafened,
  required String actionLabel,
}) {
  return _updateGuildMemberVoiceState(
    ref: ref,
    guildId: guildId,
    userId: userId,
    actionLabel: actionLabel,
    body: _memberVoiceUpdate(deaf: deafened),
  );
}

Future<void> disconnectVoiceParticipant({
  required WidgetRef ref,
  required String guildId,
  required String userId,
  required String? connectionId,
  required String actionLabel,
}) {
  return runVoiceParticipantModeration(
    ref,
    actionLabel: actionLabel,
    action: () {
      return ref
          .read(starDioProvider)
          .patch<void>(
            '/guilds/$guildId/members/$userId',
            data: buildDisconnectVoiceParticipantBody(
              connectionId: connectionId,
            ),
          );
    },
  );
}
