import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/profile/presentation/sheets/ban_member_sheet.dart';
import 'package:star_app/features/profile/presentation/sheets/timeout_member_sheet.dart';
import 'package:star_app/features/profile/presentation/sheets/user_profile_actions_sheet.dart';
import 'package:star_app/features/profile/presentation/sheets/user_profile_confirmation_sheet.dart';
import 'package:star_app/features/profile/utils/profile_menu_capabilities.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/presentation/sheets/voice_participant_menu_data.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_dart/export.dart';

List<VoiceParticipantMenuEntry> buildVoiceParticipantGuildModerationEntries({
  required BuildContext context,
  required WidgetRef ref,
  required StarLocalizations l10n,
  required String guildId,
  required String userId,
  required String username,
  required ProfileMenuCapabilities capabilities,
  required String? currentNick,
  required VoidCallback close,
}) {
  final List<VoiceParticipantMenuEntry> entries = <VoiceParticipantMenuEntry>[];

  if (capabilities.showTimeout) {
    entries.add(
      VoiceParticipantMenuActionEntry(
        label: l10n.userProfileTimeout,
        icon: PhosphorIconsFill.clock,
        isDanger: true,
        onPressed: () {
          close();
          unawaited(() async {
            final int? seconds = await TimeoutMemberSheet.show(
              context,
              username: username,
            );
            if (seconds == null) {
              return;
            }
            await UserProfileActionsSheet.runGuildModeration(
              ref,
              guildId: guildId,
              userId: userId,
              successMessage: l10n.userProfileTimeoutSuccess(username),
              errorAction: ApiErrorAction.timeoutMember,
              action: () => ref
                  .read(starClientProvider)
                  .guilds
                  .updateGuildMember(
                    guildId: guildId,
                    userId: userId,
                    body: GuildMemberUpdateRequest(
                      nick: currentNick == null
                          ? const JsonNullable.undefined()
                          : JsonNullable.of(currentNick),
                      communicationDisabledUntil: JsonNullable.of(
                        DateTime.now().toUtc().add(Duration(seconds: seconds)),
                      ),
                    ),
                  ),
            );
          }());
        },
      ),
    );
  }

  if (capabilities.showRemoveTimeout) {
    entries.add(
      VoiceParticipantMenuActionEntry(
        label: l10n.userProfileRemoveTimeout,
        icon: PhosphorIconsFill.clockClockwise,
        isDanger: true,
        onPressed: () {
          close();
          unawaited(() async {
            final bool ok = await UserProfileConfirmationSheet.show(
              context,
              title: l10n.userProfileRemoveTimeoutConfirmTitle,
              description: l10n.userProfileRemoveTimeoutConfirmDescription(
                username,
              ),
              primaryLabel: l10n.userProfileRemoveTimeout,
              primaryVariant: StarButtonVariant.dangerPrimary,
            );
            if (!ok) {
              return;
            }
            await UserProfileActionsSheet.runGuildModeration(
              ref,
              guildId: guildId,
              userId: userId,
              successMessage: l10n.userProfileRemoveTimeoutSuccess(username),
              errorAction: ApiErrorAction.removeTimeout,
              action: () => ref
                  .read(starClientProvider)
                  .guilds
                  .updateGuildMember(
                    guildId: guildId,
                    userId: userId,
                    body: GuildMemberUpdateRequest(
                      communicationDisabledUntil:
                          const JsonNullable<DateTime>.of(null),
                    ),
                  ),
            );
          }());
        },
      ),
    );
  }

  if (capabilities.canKick) {
    entries.add(
      VoiceParticipantMenuActionEntry(
        label: l10n.userProfileKick,
        icon: PhosphorIconsFill.signOut,
        isDanger: true,
        onPressed: () {
          close();
          unawaited(() async {
            final bool ok = await UserProfileConfirmationSheet.show(
              context,
              title: l10n.userProfileKickConfirmTitle(username),
              description: l10n.userProfileKickConfirmDescription(username),
              primaryLabel: l10n.userProfileKick,
              primaryVariant: StarButtonVariant.dangerPrimary,
            );
            if (!ok) {
              return;
            }
            await UserProfileActionsSheet.runGuildModeration(
              ref,
              guildId: guildId,
              userId: userId,
              successMessage: l10n.userProfileKickSuccess(username),
              errorAction: ApiErrorAction.kickMember,
              action: () => ref
                  .read(starClientProvider)
                  .guilds
                  .removeGuildMember(guildId: guildId, userId: userId),
            );
          }());
        },
      ),
    );
  }

  if (capabilities.canBan) {
    entries.add(
      VoiceParticipantMenuActionEntry(
        label: l10n.userProfileBan,
        icon: PhosphorIconsFill.gavel,
        isDanger: true,
        onPressed: () {
          close();
          unawaited(() async {
            final result = await BanMemberSheet.show(
              context,
              username: username,
            );
            if (result == null) {
              return;
            }
            await UserProfileActionsSheet.runGuildModeration(
              ref,
              guildId: guildId,
              userId: userId,
              successMessage: l10n.userProfileBanSuccess(username),
              errorAction: ApiErrorAction.banMember,
              action: () => ref
                  .read(starClientProvider)
                  .guilds
                  .banGuildMember(
                    guildId: guildId,
                    userId: userId,
                    body: GuildBanCreateRequest(
                      deleteMessageDays: result.deleteMessageDays,
                      reason: JsonNullable.of(result.reason),
                      banDurationSeconds: result.banDurationSeconds,
                    ),
                  ),
            );
          }());
        },
      ),
    );
  }

  return entries;
}
