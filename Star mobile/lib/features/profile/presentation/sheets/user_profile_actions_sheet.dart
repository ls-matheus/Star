import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/constants/user_flags.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/friends/domain/friend.dart';
import 'package:star_app/features/friends/presentation/change_friend_nickname.dart';
import 'package:star_app/features/friends/providers/friend_providers.dart';
import 'package:star_app/features/members/domain/member.dart';
import 'package:star_app/features/members/presentation/widgets/manage_member_roles_picker.dart';
import 'package:star_app/features/moderation/domain/iar_context.dart';
import 'package:star_app/features/moderation/presentation/report_flow/open_report_flow.dart';
import 'package:star_app/features/moderation/providers/local_user_spam_override_provider.dart';
import 'package:star_app/features/profile/presentation/menus/guild_member_moderation_menu_items.dart';
import 'package:star_app/features/profile/presentation/sheets/user_profile_confirmation_sheet.dart';
import 'package:star_app/features/profile/utils/profile_menu_capabilities.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/user_profile.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';
import 'package:star_app/shared/utils/user_tag.dart';
import 'package:star_dart/export.dart';

class UserProfileActionsSheet {
  UserProfileActionsSheet._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required Friend? relationship,
    required UserPartialResponse user,
    required bool isCurrentUser,
    required Offset position,
    required String displayName,
    bool hasGuildProfile = false,
    bool isShowingGlobalProfile = false,
    VoidCallback? onShowGlobalProfile,
    VoidCallback? onShowCommunityProfile,
    String? guildId,
    Message? message,
    String? avatarUrl,
    int? avatarColor,
    ProfileMenuCapabilities capabilities = ProfileMenuCapabilities.none,
    String? currentNick,
    DateTime? currentTimeoutUntil,
    List<MemberRole> allGuildRoles = const <MemberRole>[],
    Set<String> memberRoleIds = const <String>{},
    bool canManageRoles = false,
    bool isGuildOwner = false,
    MemberRole? viewerHighestRole,
    bool canReportUserProfile = false,
  }) {
    return StarActionMenu.show(
      context,
      position: position,
      builder: (menuContext, close) {
        final l10n = StarLocalizations.of(menuContext);
        final tag = formatUserTag(
          user.username,
          user.discriminator,
          uniqueUsernames: ref.read(uniqueUsernamesProvider),
          bot: user.bot ?? false,
        );
        final status = relationship?.friendStatus;
        final bool isSystem = user.system ?? false;

        final groups = <List<Widget>>[];

        if (hasGuildProfile) {
          groups.add(<Widget>[
            StarMenuItem(
              label: isShowingGlobalProfile
                  ? l10n.userProfileViewCommunityProfile
                  : l10n.userProfileViewMainProfile,
              icon: PhosphorIconsFill.userCircle,
              onPressed: () {
                close();
                if (isShowingGlobalProfile) {
                  onShowCommunityProfile?.call();
                  return;
                }
                onShowGlobalProfile?.call();
              },
            ),
          ]);
        }

        groups.add(<Widget>[
          StarMenuItem(
            label: l10n.userProfileCopyUsername,
            icon: PhosphorIconsFill.copy,
            onPressed: () async {
              close();
              await copyToClipboard(context: menuContext, value: tag);
            },
          ),
          StarMenuItem(
            label: l10n.userProfileCopyUserId,
            icon: PhosphorIconsFill.identificationCard,
            onPressed: () async {
              close();
              await copyToClipboard(context: menuContext, value: user.id);
            },
          ),
        ]);

        if (guildId != null) {
          if (capabilities.canChangeNickname) {
            final List<Widget> nicknameItems = <Widget>[];
            appendGuildMemberModerationMenuItems(
              items: nicknameItems,
              context: context,
              ref: ref,
              close: close,
              l10n: l10n,
              guildId: guildId,
              userId: user.id,
              username: user.username,
              capabilities: capabilities,
              currentNick: currentNick,
              isCurrentUser: isCurrentUser,
              includeNickname: true,
              includeModerationActions: false,
            );
            groups.add(nicknameItems);
          }

          if (capabilities.canTransfer) {
            groups.add(<Widget>[
              StarMenuItem(
                label: l10n.userProfileTransferOwnership,
                icon: PhosphorIconsFill.crown,
                isDanger: true,
                onPressed: () async {
                  close();
                  final ok = await UserProfileConfirmationSheet.show(
                    context,
                    title: l10n.userProfileTransferConfirmTitle,
                    description: l10n.userProfileTransferConfirmDescription(
                      user.username,
                    ),
                    primaryLabel: l10n.userProfileTransferOwnership,
                    primaryVariant: StarButtonVariant.dangerPrimary,
                  );
                  if (!ok) {
                    return;
                  }
                  await _runGuildModeration(
                    ref,
                    guildId: guildId,
                    userId: user.id,
                    successMessage: l10n.userProfileTransferSuccess,
                    errorAction: ApiErrorAction.transferOwnership,
                    errorSubject: user.username,
                    action: () => ref
                        .read(starClientProvider)
                        .guilds
                        .transferGuildOwnership(
                          guildId: guildId,
                          body: GuildTransferOwnershipWithVerificationRequest(
                            newOwnerId: user.id,
                          ),
                        ),
                  );
                },
              ),
            ]);
          }

          if (capabilities.showManageRoles) {
            groups.add(<Widget>[
              StarMenuItem(
                label: l10n.permissionManageRoles,
                icon: PhosphorIconsFill.userGear,
                onPressed: () async {
                  close();
                  await ManageMemberRolesSheet.show(
                    context,
                    ref,
                    guildId: guildId,
                    userId: user.id,
                    allGuildRoles: allGuildRoles,
                    memberRoleIds: memberRoleIds,
                    canManageRoles: canManageRoles,
                    isGuildOwner: isGuildOwner,
                    viewerHighestRole: viewerHighestRole,
                  );
                },
              ),
            ]);
          }

          final List<Widget> moderationItems = <Widget>[];
          appendGuildMemberModerationMenuItems(
            items: moderationItems,
            context: context,
            ref: ref,
            close: close,
            l10n: l10n,
            guildId: guildId,
            userId: user.id,
            username: user.username,
            capabilities: capabilities,
            currentNick: currentNick,
            isCurrentUser: isCurrentUser,
          );
          if (moderationItems.isNotEmpty) {
            groups.add(moderationItems);
          }
        }

        if (!isCurrentUser) {
          if (status == FriendStatus.accepted) {
            groups.add(<Widget>[
              StarMenuItem(
                label: l10n.dmChangeFriendNickname,
                icon: PhosphorIconsFill.pencilSimple,
                onPressed: () async {
                  close();
                  await showChangeFriendNicknameSheet(
                    context,
                    ref,
                    userId: user.id,
                    username: user.username,
                    currentNick: relationship?.nickname,
                  );
                },
              ),
              StarMenuItem(
                label: l10n.userProfileRemoveFriend,
                icon: PhosphorIconsFill.userMinus,
                isDanger: true,
                onPressed: () async {
                  close();
                  final ok = await UserProfileConfirmationSheet.show(
                    context,
                    title: l10n.userProfileRemoveFriendConfirmTitle,
                    description: l10n.userProfileRemoveFriendConfirmDescription(
                      user.username,
                    ),
                    primaryLabel: l10n.userProfileRemoveFriend,
                    primaryVariant: StarButtonVariant.dangerPrimary,
                  );
                  if (ok) {
                    await _runRepoAction(
                      ref,
                      ApiErrorAction.removeFriend,
                      () => ref
                          .read(friendRepositoryProvider)
                          .removeRelationship(user.id),
                    );
                  }
                },
              ),
            ]);
          }

          final reportBlockItems = <Widget>[];
          final reportableMessage = message;
          if (reportableMessage != null && reportableMessage.isReportable) {
            reportBlockItems.add(
              StarMenuItem(
                label: l10n.userProfileReportMessage,
                icon: PhosphorIconsFill.flag,
                isDanger: true,
                onPressed: () async {
                  close();
                  await openReportFlow(
                    context,
                    iarContext: IarMessageContext(
                      message: reportableMessage,
                      guildId: guildId,
                    ),
                  );
                },
              ),
            );
          }
          if (canReportUserProfile) {
            reportBlockItems.add(
              StarMenuItem(
                label: l10n.userProfileReportUserProfile,
                icon: PhosphorIconsFill.flag,
                isDanger: true,
                onPressed: () async {
                  close();
                  await openReportFlow(
                    context,
                    iarContext: IarUserContext(
                      userId: user.id,
                      username: tag,
                      displayName: displayName,
                      avatarUrl: avatarUrl,
                      avatarColor: avatarColor,
                      guildId: guildId,
                    ),
                  );
                },
              ),
            );
          }
          if (!isSystem) {
            if (status == FriendStatus.blocked) {
              reportBlockItems.add(
                StarMenuItem(
                  label: l10n.userProfileUnblockUser,
                  icon: PhosphorIconsFill.prohibit,
                  onPressed: () async {
                    close();
                    final ok = await UserProfileConfirmationSheet.show(
                      context,
                      title: l10n.userProfileUnblockConfirmTitle,
                      description: l10n.userProfileUnblockConfirmDescription(
                        user.username,
                      ),
                      primaryLabel: l10n.userProfileUnblockUser,
                      primaryVariant: StarButtonVariant.primary,
                    );
                    if (ok) {
                      await _runRepoAction(
                        ref,
                        ApiErrorAction.unblockUser,
                        () => ref
                            .read(friendRepositoryProvider)
                            .removeRelationship(user.id),
                      );
                    }
                  },
                ),
              );
            } else {
              reportBlockItems.add(
                StarMenuItem(
                  label: l10n.userProfileBlockUser,
                  icon: PhosphorIconsFill.prohibit,
                  isDanger: true,
                  onPressed: () async {
                    close();
                    final ok = await UserProfileConfirmationSheet.show(
                      context,
                      title: l10n.userProfileBlockConfirmTitle,
                      description: l10n.userProfileBlockConfirmDescription(
                        user.username,
                      ),
                      primaryLabel: l10n.userProfileBlockUser,
                      primaryVariant: StarButtonVariant.dangerPrimary,
                    );
                    if (ok) {
                      await _runRepoAction(
                        ref,
                        ApiErrorAction.blockUser,
                        () => ref
                            .read(friendRepositoryProvider)
                            .blockUser(user.id),
                      );
                    }
                  },
                ),
              );
            }
          }
          groups.add(reportBlockItems);
        }

        final bool developerMode = ref.read(
          userSettingsViewModelProvider.select((s) => s.developerMode),
        );
        if (developerMode && !isCurrentUser) {
          final LocalUserSpamOverrideState spamOverride = ref.read(
            localUserSpamOverrideProvider,
          );
          final LocalUserSpamOverride spamNotifier = ref.read(
            localUserSpamOverrideProvider.notifier,
          );
          final bool isLocalSpammer = spamOverride.spammerUserIds.contains(
            user.id,
          );
          final bool isLocalNotSpammer = spamOverride.notSpammerUserIds
              .contains(user.id);
          final bool isServerSpammerUser = isServerSpammer(user.flags);
          final List<Widget> spamOverrideItems = <Widget>[
            StarMenuItem(
              label: l10n.devMarkAsSpamLocally,
              icon: isLocalSpammer
                  ? PhosphorIconsFill.check
                  : PhosphorIconsFill.bug,
              onPressed: () {
                close();
                unawaited(
                  isLocalSpammer
                      ? spamNotifier.clearOverride(user.id)
                      : spamNotifier.markAsSpammer(user.id),
                );
              },
            ),
          ];
          if (isServerSpammerUser) {
            spamOverrideItems.add(
              StarMenuItem(
                label: l10n.devIgnoreSpamFlag,
                icon: isLocalNotSpammer
                    ? PhosphorIconsFill.check
                    : PhosphorIconsFill.bug,
                onPressed: () {
                  close();
                  unawaited(
                    isLocalNotSpammer
                        ? spamNotifier.clearOverride(user.id)
                        : spamNotifier.markAsNotSpammer(user.id),
                  );
                },
              ),
            );
          }
          groups.add(spamOverrideItems);
        }

        final widgets = <Widget>[];
        for (final group in groups) {
          if (group.isEmpty) {
            continue;
          }
          if (widgets.isNotEmpty) {
            widgets.add(const StarMenuDivider());
          }
          widgets.addAll(group);
        }
        return widgets;
      },
    );
  }

  static Future<void> _updateGuildMemberNickname({
    required WidgetRef ref,
    required String guildId,
    required String userId,
    required String? nick,
    required bool isCurrentUser,
  }) async {
    if (isCurrentUser) {
      await ref
          .read(starClientProvider)
          .guilds
          .updateCurrentGuildMember(
            guildId: guildId,
            body: MyGuildMemberUpdateRequest(nick: JsonNullable.of(nick)),
          );
      return;
    }
    await ref
        .read(starDioProvider)
        .patch<void>(
          '/guilds/$guildId/members/$userId',
          data: <String, dynamic>{'nick': nick},
        );
  }

  static Future<void> runGuildModeration(
    WidgetRef ref, {
    required String guildId,
    required String userId,
    required String successMessage,
    required ApiErrorAction errorAction,
    required Future<void> Function() action,
  }) => _runGuildModeration(
    ref,
    guildId: guildId,
    userId: userId,
    successMessage: successMessage,
    errorAction: errorAction,
    action: action,
  );

  static Future<void> updateGuildMemberNickname({
    required WidgetRef ref,
    required String guildId,
    required String userId,
    required String? nick,
    required bool isCurrentUser,
  }) => _updateGuildMemberNickname(
    ref: ref,
    guildId: guildId,
    userId: userId,
    nick: nick,
    isCurrentUser: isCurrentUser,
  );

  static Future<void> _runGuildModeration(
    WidgetRef ref, {
    required String guildId,
    required String userId,
    required String successMessage,
    required ApiErrorAction errorAction,
    required Future<void> Function() action,
    String? errorSubject,
  }) async {
    try {
      await action();
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: successMessage,
              variant: StarToastVariant.success,
            ),
          );
      ref.invalidate(userProfileProvider(userId: userId, guildId: guildId));
    } on Object catch (e, st) {
      talker.error('[UserProfileActionsSheet] moderation failed: $e', e, st);
      await showApiErrorFromRoot(
        errorAction,
        e,
        details: ApiErrorDetails(subject: errorSubject),
      );
    }
  }

  static Future<void> _runRepoAction(
    WidgetRef ref,
    ApiErrorAction errorAction,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(friendsListProvider);
    } on Object catch (e, st) {
      talker.error('[UserProfileActionsSheet] action failed: $e', e, st);
      if (!ref.context.mounted) {
        return;
      }
      await showApiError(ref.context, errorAction, e);
    }
  }
}
