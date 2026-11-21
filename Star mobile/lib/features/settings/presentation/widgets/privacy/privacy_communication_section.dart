import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/privacy_permission.dart';
import 'package:star_app/features/settings/providers/view_models/privacy_dashboard_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class PrivacyCommunicationSection extends ConsumerWidget {
  const PrivacyCommunicationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      privacyDashboardViewModelProvider(watchAccountUserId(ref)),
    );
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final vm = ref.read(
      privacyDashboardViewModelProvider(readAccountUserId(ref)).notifier,
    );

    return StarSettingsSection(
      sectionId: 'communication',
      title: l10n.privacyDashboardCommunicationSection,
      children: [
        StarSettingsSubsection(
          title: l10n.privacyDashboardIncomingCallsTitle,
          children: [
            StarSelect<PermissionMode>(
              label: l10n.privacyDashboardAllowedCallers,
              value: state.incomingCallMode,
              enableSearch: false,
              items: [
                StarSelectItem(
                  value: PermissionMode.nobody,
                  label: l10n.privacyDashboardIncomingCallNobodyDesc,
                ),
                StarSelectItem(
                  value: PermissionMode.friendsOnly,
                  label: l10n.privacyDashboardIncomingCallFriendsOnlyDesc,
                ),
                StarSelectItem(
                  value: PermissionMode.custom,
                  label: l10n.privacyDashboardIncomingCallCustomDesc,
                ),
                StarSelectItem(
                  value: PermissionMode.everyone,
                  label: l10n.privacyDashboardIncomingCallEveryoneDesc,
                ),
              ],
              onChanged: (mode) => unawaited(
                vm.updateIncomingCallFlags(
                  incomingCallFlagsForMode(mode, state.incomingCallFlags),
                ),
              ),
            ),
            if (state.incomingCallMode == PermissionMode.custom) ...[
              SizedBox(height: layout.s2),
              StarSubsectionLabel(l10n.privacyDashboardAdditionalGroups),
              SizedBox(height: layout.s2),
              StarSettingsSwitchGroup(
                children: [
                  StarSettingsSwitchItem.grouped(
                    label: l10n.privacyDashboardFriendRequestsFriendsOfFriends,
                    value: state.callFriendsOfFriends,
                    onChanged: (value) => unawaited(
                      vm.updateIncomingCallFlags(
                        toggleIncomingCallFlag(
                          currentFlags: state.incomingCallFlags,
                          flag: IncomingCallFlag.friendsOfFriends,
                          enabled: value,
                        ),
                      ),
                    ),
                  ),
                  StarSettingsSwitchItem.grouped(
                    label: l10n.privacyDashboardFriendRequestsCommunityMembers,
                    value: state.callGuildMembers,
                    onChanged: (value) => unawaited(
                      vm.updateIncomingCallFlags(
                        toggleIncomingCallFlag(
                          currentFlags: state.incomingCallFlags,
                          flag: IncomingCallFlag.guildMembers,
                          enabled: value,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (state.incomingCallMode != PermissionMode.nobody) ...[
              SizedBox(height: layout.s2),
              StarSubsectionLabel(l10n.privacyDashboardRingBehavior),
              SizedBox(height: layout.s2),
              StarSettingsSwitchGroup(
                children: [
                  StarSettingsSwitchItem.grouped(
                    label: l10n.privacyDashboardSilentCalls,
                    value: state.silentCallsEnabled,
                    onChanged: (value) {
                      var flags = state.incomingCallFlags;
                      if (value) {
                        flags |= IncomingCallFlag.silentEveryone;
                      } else {
                        flags &= ~IncomingCallFlag.silentEveryone;
                      }
                      unawaited(vm.updateIncomingCallFlags(flags));
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
        StarSettingsSubsection(
          title: l10n.privacyDashboardGroupDmTitle,
          children: [
            StarSelect<PermissionMode>(
              label: l10n.privacyDashboardAllowedInvites,
              value: state.groupDmAddMode,
              enableSearch: false,
              items: [
                StarSelectItem(
                  value: PermissionMode.nobody,
                  label: l10n.privacyDashboardGroupDmNobodyDesc,
                ),
                StarSelectItem(
                  value: PermissionMode.friendsOnly,
                  label: l10n.privacyDashboardGroupDmFriendsOnlyDesc,
                ),
                StarSelectItem(
                  value: PermissionMode.custom,
                  label: l10n.privacyDashboardGroupDmCustomDesc,
                ),
                StarSelectItem(
                  value: PermissionMode.everyone,
                  label: l10n.privacyDashboardGroupDmEveryoneDesc,
                ),
              ],
              onChanged: (mode) => unawaited(
                vm.updateGroupDmAddPermissionFlags(
                  groupDmAddFlagsForMode(mode, state.groupDmAddPermissionFlags),
                ),
              ),
            ),
            if (state.groupDmAddMode == PermissionMode.custom) ...[
              SizedBox(height: layout.s2),
              StarSubsectionLabel(l10n.privacyDashboardAdditionalGroups),
              SizedBox(height: layout.s2),
              StarSettingsSwitchGroup(
                children: [
                  StarSettingsSwitchItem.grouped(
                    label: l10n.privacyDashboardFriendRequestsFriendsOfFriends,
                    value: state.groupDmFriendsOfFriends,
                    onChanged: (value) => unawaited(
                      vm.updateGroupDmAddPermissionFlags(
                        toggleGroupDmAddFlag(
                          currentFlags: state.groupDmAddPermissionFlags,
                          flag: GroupDmAddPermissionFlag.friendsOfFriends,
                          enabled: value,
                        ),
                      ),
                    ),
                  ),
                  StarSettingsSwitchItem.grouped(
                    label: l10n.privacyDashboardFriendRequestsCommunityMembers,
                    value: state.groupDmGuildMembers,
                    onChanged: (value) => unawaited(
                      vm.updateGroupDmAddPermissionFlags(
                        toggleGroupDmAddFlag(
                          currentFlags: state.groupDmAddPermissionFlags,
                          flag: GroupDmAddPermissionFlag.guildMembers,
                          enabled: value,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
