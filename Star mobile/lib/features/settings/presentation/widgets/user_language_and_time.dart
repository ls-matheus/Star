import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/profile/providers/user_settings_status_provider.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:star_app/features/settings/providers/sync/user_settings_sync_service.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/app_locale_provider.dart';
import 'package:star_app/l10n/star_localizations_utils.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/app_locale_display.dart';
import 'package:star_app/shared/utils/user_date_formatting.dart';
import 'package:star_dart/export.dart';
import 'package:star_dart/models/locale.dart' as sdk;

class UserLanguageAndTime extends ConsumerWidget {
  const UserLanguageAndTime({super.key, this.scrollController});

  final ScrollController? scrollController;

  static final DateTime _sampleDateTime = DateTime(2025, 1, 1, 14, 30);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final TimeFormatTypes timeFormat = ref.watch(timeFormatPreferenceProvider);
    final AppearancePreferencesState appearance = ref.watch(
      appearancePreferencesProvider,
    );
    final UserSettingsResponse? settings = ref.watch(
      userSettingsStatusProvider,
    );
    final String appLocale = ref
        .watch(effectiveAppLocaleProvider)
        .toLanguageTag();
    final String systemLocale = ref
        .watch(systemLocalesProvider)
        .first
        .toLanguageTag();
    final String displayLocale = Localizations.localeOf(context).toString();
    final sdk.Locale? storedLocale = settings?.locale;
    final sdk.Locale? selectedLocale =
        storedLocale != null &&
            tryFlutterLocaleFromSdkLocale(storedLocale) != null
        ? storedLocale
        : null;

    void showSyncFailedToast() {
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.languageAndTimeTimeFormatSyncFailed,
              variant: StarToastVariant.danger,
            ),
          );
    }

    Future<void> changeTimeFormat(TimeFormatTypes value) async {
      try {
        await ref
            .read(timeFormatPreferenceProvider.notifier)
            .setTimeFormat(value);
      } on Object {
        showSyncFailedToast();
      }
    }

    Future<void> changeUseSystemLocale({required bool value}) async {
      try {
        await ref
            .read(appearancePreferencesProvider.notifier)
            .setUseSystemLocaleForTimeFormat(value: value);
      } on Object {
        showSyncFailedToast();
      }
    }

    String autoDescription() {
      final bool useSystemLocale = appearance.useSystemLocaleForTimeFormat;
      final String effectiveLocale = useSystemLocale ? systemLocale : appLocale;
      final bool use12Hour = localeUses12Hour(effectiveLocale);
      final String format = formatUserTime(
        _sampleDateTime,
        displayLocale,
        use12Hour: use12Hour,
      );
      if (useSystemLocale) {
        return l10n.languageAndTimeTimeFormatSystemLocale(format);
      }
      return l10n.languageAndTimeTimeFormatAppLanguage(format);
    }

    final String twelveHourExample = formatUserTime(
      _sampleDateTime,
      displayLocale,
      use12Hour: true,
    );
    final String twentyFourHourExample = formatUserTime(
      _sampleDateTime,
      displayLocale,
      use12Hour: false,
    );

    Future<void> changeAppLocale(sdk.Locale value) async {
      try {
        await ref.read(userSettingsSyncProvider).pushLocale(value);
      } on Object {
        showSyncFailedToast();
      }
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: settingsScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarSettingsSection(
            title: l10n.languageAndTimeTimeFormatSectionTitle,
            description: l10n.languageAndTimeTimeFormatSectionDescription,
            isFirst: true,
            children: [
              Semantics(
                label: l10n.languageAndTimeTimeFormatSelectionLabel,
                container: true,
                child: StarRadioGroup<TimeFormatTypes>(
                  value: timeFormat,
                  onChanged: (value) => unawaited(changeTimeFormat(value)),
                  items: [
                    StarRadioItem(
                      value: TimeFormatTypes.auto,
                      label: l10n.languageAndTimeTimeFormatAuto,
                      description: autoDescription(),
                    ),
                    StarRadioItem(
                      value: TimeFormatTypes.twelveHour,
                      label: l10n.languageAndTimeTimeFormat12Hour,
                      description: twelveHourExample,
                    ),
                    StarRadioItem(
                      value: TimeFormatTypes.twentyFourHour,
                      label: l10n.languageAndTimeTimeFormat24Hour,
                      description: twentyFourHourExample,
                    ),
                  ],
                ),
              ),
              if (timeFormat == TimeFormatTypes.auto) ...[
                SizedBox(height: layout.s4),
                StarSettingsSwitchItem(
                  label: l10n.languageAndTimeUseSystemLocaleForTimeFormat,
                  value: appearance.useSystemLocaleForTimeFormat,
                  onChanged: (value) =>
                      unawaited(changeUseSystemLocale(value: value)),
                ),
              ],
            ],
          ),
          StarSettingsSection(
            title: l10n.languageAndTimeLanguageSectionTitle,
            description: l10n.languageAndTimeLanguageSectionDescription,
            children: [
              StarSelect<sdk.Locale>(
                hint: l10n.languageAndTimeLanguageSectionTitle,
                value: selectedLocale,
                enableSearch: false,
                scrollableSheet: true,
                stretch: true,
                items: <StarSelectItem<sdk.Locale>>[
                  for (final sdk.Locale locale in sortedAppSdkLocales())
                    StarSelectItem<sdk.Locale>(
                      value: locale,
                      label: appLocaleDisplayInfo(locale).label,
                      description: appLocaleDisplayInfo(locale).nativeName,
                      searchText: appLocaleDisplayInfo(locale).searchText,
                      leading: appLocaleFlag(locale),
                    ),
                ],
                onChanged: (sdk.Locale value) =>
                    unawaited(changeAppLocale(value)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
