import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/features/settings/providers/view_models/privacy_dashboard_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

class PrivacyProfileSection extends ConsumerWidget {
  const PrivacyProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      privacyDashboardViewModelProvider(watchAccountUserId(ref)),
    );
    final l10n = StarLocalizations.of(context);
    final vm = ref.read(
      privacyDashboardViewModelProvider(readAccountUserId(ref)).notifier,
    );

    return StarSettingsSection(
      sectionId: 'profile-privacy',
      title: l10n.privacyDashboardProfilePrivacySection,
      isFirst: true,
      children: [
        StarSettingsSubsection(
          title: l10n.privacyDashboardProfilePrivacyTitle,
          children: [
            StarRadioGroup<ProfilePrivacyLevel>(
              value: state.profilePrivacy,
              items: [
                StarRadioItem(
                  value: ProfilePrivacyLevel.allGuilds,
                  label: l10n.privacyDashboardProfilePrivacyAllCommunities,
                  description:
                      l10n.privacyDashboardProfilePrivacyAllCommunitiesDesc,
                ),
                StarRadioItem(
                  value: ProfilePrivacyLevel.smallGuildsOnly,
                  label: l10n.privacyDashboardProfilePrivacySmallCommunities,
                  description:
                      l10n.privacyDashboardProfilePrivacySmallCommunitiesDesc,
                ),
                StarRadioItem(
                  value: ProfilePrivacyLevel.friendsOnly,
                  label: l10n.privacyDashboardProfilePrivacyFriendsOnly,
                  description:
                      l10n.privacyDashboardProfilePrivacyFriendsOnlyDesc,
                ),
              ],
              onChanged: (value) => unawaited(vm.updateProfilePrivacy(value)),
            ),
          ],
        ),
      ],
    );
  }
}
