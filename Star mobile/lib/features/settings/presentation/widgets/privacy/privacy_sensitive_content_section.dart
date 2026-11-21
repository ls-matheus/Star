import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/mature_content/domain/mature_content_types.dart';
import 'package:star_app/features/mature_content/providers/sensitive_content_provider.dart';
import 'package:star_app/features/settings/presentation/widgets/privacy/privacy_age_range_unlock.dart';
import 'package:star_app/features/settings/providers/view_models/privacy_dashboard_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class PrivacySensitiveContentSection extends ConsumerWidget {
  const PrivacySensitiveContentSection({super.key});

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
    final SensitiveContentState sensitive = ref.watch(sensitiveContentProvider);
    final bool showLocked = sensitive.showLocked;
    final bool adultDmChoices = state.isAdult && !showLocked;
    final bool guildEditable = state.isAdult && !showLocked;

    final adultFilterItems = <StarRadioItem<int>>[
      StarRadioItem(value: 0, label: l10n.sensitiveContentFilterShow),
      StarRadioItem(value: 1, label: l10n.sensitiveContentFilterBlur),
      StarRadioItem(value: 2, label: l10n.sensitiveContentFilterBlock),
    ];
    final minorFriendFilterItems = <StarRadioItem<int>>[
      StarRadioItem(value: 1, label: l10n.sensitiveContentFilterBlur),
      StarRadioItem(value: 2, label: l10n.sensitiveContentFilterBlock),
    ];
    final guildFilterItems = <StarRadioItem<int>>[
      StarRadioItem(value: 0, label: l10n.sensitiveContentFilterShow),
      StarRadioItem(value: 1, label: l10n.sensitiveContentFilterBlur),
    ];

    return StarSettingsSection(
      sectionId: 'sensitive-content',
      title: l10n.privacyDashboardSensitiveContentSection,
      children: [
        StarSettingsSubsection(
          children: [
            StarRadioGroup<int>(
              label: l10n.sensitiveContentFriendDmLabel,
              value: state.effectiveFriendDmFilter,
              items: adultDmChoices ? adultFilterItems : minorFriendFilterItems,
              onChanged: vm.editFriendDmFilter,
            ),
            Opacity(
              opacity: state.isAdult ? 1 : 0.5,
              child: IgnorePointer(
                ignoring: !state.isAdult,
                child: StarRadioGroup<int>(
                  label: l10n.sensitiveContentNonFriendDmLabel,
                  value: state.effectiveNonFriendDmFilter,
                  items: adultDmChoices
                      ? adultFilterItems
                      : minorFriendFilterItems,
                  onChanged: vm.editNonFriendDmFilter,
                ),
              ),
            ),
            Opacity(
              opacity: guildEditable ? 1 : 0.5,
              child: IgnorePointer(
                ignoring: !guildEditable,
                child: StarRadioGroup<int>(
                  label: l10n.sensitiveContentGuildLabel,
                  value: state.effectiveGuildFilter,
                  items: guildFilterItems,
                  onChanged: vm.editGuildFilter,
                ),
              ),
            ),
            const PrivacyAgeRangeUnlock(),
            if (sensitive.access == MatureAccess.appLocked)
              Text(
                l10n.sensitiveContentAppLockedHint,
                style: context.textStyles.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            if (state.isSensitiveContentDirty)
              Row(
                children: [
                  Expanded(
                    child: StarButton.secondary(
                      label: l10n.sensitiveContentResetButton,
                      onPressed: vm.resetSensitiveContent,
                    ),
                  ),
                  SizedBox(width: layout.s2),
                  Expanded(
                    child: StarButton.primary(
                      label: l10n.sensitiveContentSaveButton,
                      isLoading: state.isSavingSensitiveContent,
                      onPressedAsync: () => vm.saveSensitiveContent(
                        failureMessage:
                            l10n.privacyDashboardSensitiveContentSaveFailed,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
