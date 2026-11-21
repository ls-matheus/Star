import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/profile/domain/profile_timezone_privacy_flags.dart';
import 'package:star_app/features/profile/utils/timezone_catalog.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

const String _kTimezoneNotSetValue = '';
const String _kTimezoneIdentifierExample = 'America/New_York';

List<TimezoneCatalogOption>? _cachedCatalog;
List<StarSelectItem<String>>? _cachedTimezoneSelectItems;

List<TimezoneCatalogOption> _timezoneCatalog() {
  return _cachedCatalog ??= buildTimezoneCatalogOptions();
}

List<StarSelectItem<String>> _timezoneSelectItems(String notSetLabel) {
  _cachedTimezoneSelectItems ??= _timezoneCatalog()
      .map(
        (TimezoneCatalogOption option) => StarSelectItem<String>(
          value: option.id,
          label: option.label,
          searchText: option.searchText,
        ),
      )
      .toList(growable: false);
  return <StarSelectItem<String>>[
    StarSelectItem<String>(
      value: _kTimezoneNotSetValue,
      label: notSetLabel,
      searchText: notSetLabel,
    ),
    ..._cachedTimezoneSelectItems!,
  ];
}

class ProfileLocalTimeSheet {
  ProfileLocalTimeSheet._();

  static Future<void> show(BuildContext context, {required bool disabled}) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String title = l10n.profileLocalTimeSettingsTitle;
    if (isMobileLayout(context)) {
      return StarBottomSheet.showScrollable<void>(
        context,
        title: title,
        useRootNavigator: true,
        builder:
            (
              BuildContext sheetContext,
              ScrollController scrollController,
              VoidCallback _,
            ) {
              return _ProfileLocalTimeEditorBody(
                disabled: disabled,
                scrollController: scrollController,
              );
            },
      );
    }
    return StarModal.show<void>(
      context,
      title: title,
      centered: true,
      useRootNavigator: true,
      builder: (BuildContext dialogContext, VoidCallback _) {
        return _ProfileLocalTimeEditorBody(disabled: disabled);
      },
      actionsBuilder: (void Function([void]) pop) => <Widget>[
        StarButton.secondary(onPressed: () => pop(), label: l10n.uiClose),
      ],
    );
  }
}

class _ProfileLocalTimeEditorBody extends ConsumerWidget {
  const _ProfileLocalTimeEditorBody({
    required this.disabled,
    this.scrollController,
  });

  final bool disabled;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserSettingsViewState state = ref.watch(
      userSettingsViewModelProvider,
    );
    final UserSettingsViewModel vm = ref.read(
      userSettingsViewModelProvider.notifier,
    );
    final StarLocalizations l10n = StarLocalizations.of(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final String productName = ref.watch(
      instanceRuntimeConfigProvider.select((config) => config.productName),
    );

    final String? timezone = state.effectiveTimezone;
    final int privacyFlags = state.effectiveTimezonePrivacyFlags;
    final bool hasTimezone = timezone != null && timezone.isNotEmpty;
    final bool everyoneEnabled = hasProfileTimezonePrivacyFlag(
      privacyFlags,
      ProfileTimezonePrivacyFlags.everyone,
    );

    bool hasFlag(int flag) => hasProfileTimezonePrivacyFlag(privacyFlags, flag);

    void togglePrivacy(int flag, {required bool enabled}) {
      final int next = enabled ? privacyFlags | flag : privacyFlags & ~flag;
      vm.updateTimezonePrivacyFlags(next);
    }

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.profileLocalTimePrivacyNote(
            _kTimezoneIdentifierExample,
            productName,
          ),
          style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: layout.s6),
        StarSelect<String>(
          label: l10n.profileLocalTimeTimezoneLabel,
          description: l10n.profileLocalTimeTimezoneHelp(productName),
          searchHint: l10n.profileLocalTimeSearchTimezones,
          value: timezone ?? _kTimezoneNotSetValue,
          items: _timezoneSelectItems(l10n.profileLocalTimeNotSet),
          enabled: !disabled,
          scrollableSheet: true,
          stretch: true,
          onChanged: (String value) {
            vm.updateTimezone(value == _kTimezoneNotSetValue ? null : value);
          },
        ),
        SizedBox(height: layout.s6),
        StarSwitchGroup(
          children: <Widget>[
            StarSwitchGroupItem(
              label: l10n.profileLocalTimePrivacyEveryone,
              description: l10n.profileLocalTimePrivacyEveryoneDesc,
              value:
                  hasTimezone && hasFlag(ProfileTimezonePrivacyFlags.everyone),
              enabled: !disabled && hasTimezone,
              onChanged: (bool value) => togglePrivacy(
                ProfileTimezonePrivacyFlags.everyone,
                enabled: value,
              ),
            ),
            StarSwitchGroupItem(
              label: l10n.profileLocalTimePrivacyFriends,
              description: l10n.profileLocalTimePrivacyFriendsDesc,
              value:
                  hasTimezone &&
                  (everyoneEnabled ||
                      hasFlag(ProfileTimezonePrivacyFlags.friends)),
              enabled: !disabled && hasTimezone && !everyoneEnabled,
              onChanged: (bool value) => togglePrivacy(
                ProfileTimezonePrivacyFlags.friends,
                enabled: value,
              ),
            ),
            StarSwitchGroupItem(
              label: l10n.profileLocalTimePrivacyCommunityMembers,
              description: l10n.profileLocalTimePrivacyCommunityMembersDesc,
              value:
                  hasTimezone &&
                  (everyoneEnabled ||
                      hasFlag(ProfileTimezonePrivacyFlags.mutualGuilds)),
              enabled: !disabled && hasTimezone && !everyoneEnabled,
              onChanged: (bool value) => togglePrivacy(
                ProfileTimezonePrivacyFlags.mutualGuilds,
                enabled: value,
              ),
            ),
          ],
        ),
      ],
    );

    if (scrollController != null) {
      return SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(layout.s4, layout.s2, layout.s4, 0),
        child: content,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.s2),
      child: content,
    );
  }
}
