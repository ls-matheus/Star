import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/observability/observability_reporting_provider.dart';
import 'package:star_app/features/settings/presentation/sheets/advanced_configure_sheets.dart';
import 'package:star_app/features/settings/presentation/sheets/advanced_search_sheets.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/preferences/advanced_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/local_settings_provider.dart';
import 'package:star_app/features/settings/providers/preferences/voice_settings_provider.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/settings/utils/user_settings/advanced_setting_visibility.dart';
import 'package:star_app/features/settings/utils/user_settings/user_settings_domain_actions.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/domain/voice_settings_state.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/external_links/external_link_utils.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

class UserAdvancedSettings extends ConsumerWidget {
  const UserAdvancedSettings({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = StarLocalizations.of(context);

    return SingleChildScrollView(
      controller: scrollController,
      padding: settingsScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarSettingsSection(
            sectionId: 'advanced-settings-privacy',
            title: l10n.advancedSettingsCategoryPrivacy,
            isFirst: true,
            children: [
              StarSettingsSwitchItem(
                label: l10n.advancedSettingPreuploadAttachmentsLabel,
                description:
                    l10n.advancedSettingPreuploadAttachmentsDescription,
                value: ref.watch(
                  advancedPreferencesProvider.select(
                    (state) => state.preuploadMessageAttachments,
                  ),
                ),
                onChanged: (value) => ref
                    .read(advancedPreferencesProvider.notifier)
                    .setPreuploadMessageAttachments(value: value),
              ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingStripTrackingLabel,
                description: l10n.advancedSettingStripTrackingDescription,
                value: ref.watch(
                  chatPreferencesProvider.select((state) => state.sanitizeUrls),
                ),
                onChanged: (value) => ref
                    .read(chatPreferencesProvider.notifier)
                    .setSanitizeUrls(value: value),
              ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingTrustAllLinksLabel,
                description: trustedDomainsDescription(
                  l10n: l10n,
                  trustAll: ref.watch(
                    userSettingsViewModelProvider.select(
                      (state) => state.trustAllDomains,
                    ),
                  ),
                  trustedCount: ref.watch(
                    userSettingsViewModelProvider.select(
                      (state) => state.trustedDomainsCount,
                    ),
                  ),
                ),
                value: ref.watch(
                  userSettingsViewModelProvider.select(
                    (state) => state.trustAllDomains,
                  ),
                ),
                onChanged: (value) =>
                    handleTrustAllDomainsChange(context, ref, value: value),
              ),
              StarSettingsConfigureRow(
                title: l10n.advancedSettingScreenSharePreviewBehaviorLabel,
                description:
                    l10n.advancedSettingScreenSharePreviewBehaviorDescription,
                configureLabel: l10n.advancedSettingsConfigure,
                onConfigure: () => showAdvancedScreenSharePreviewSheet(context),
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'advanced-settings-appearance',
            title: l10n.advancedSettingsCategoryAppearance,
            children: [
              StarSettingsSwitchItem(
                label: l10n.advancedSettingShowNekoLabel,
                description: isTouchPrimaryInput(ref)
                    ? l10n.advancedSettingShowNekoDescriptionTouch
                    : l10n.advancedSettingShowNekoDescription,
                value: ref.watch(
                  appearancePreferencesProvider.select(
                    (state) => state.showNeko,
                  ),
                ),
                onChanged: (value) => ref
                    .read(appearancePreferencesProvider.notifier)
                    .setShowNeko(value: value),
              ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingMobileSplashZoomAnimationLabel,
                description:
                    l10n.advancedSettingMobileSplashZoomAnimationDescription,
                value: ref.watch(
                  appearancePreferencesProvider.select(
                    (state) => state.mobileSplashZoomAnimation,
                  ),
                ),
                onChanged: (value) => ref
                    .read(appearancePreferencesProvider.notifier)
                    .setMobileSplashZoomAnimation(value: value),
              ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingSplashQuotesLabel,
                description: l10n.advancedSettingSplashQuotesDescription,
                value: ref.watch(
                  localSettingsProvider.select(
                    (state) => state.splashQuotesEnabled,
                  ),
                ),
                onChanged: (value) => ref
                    .read(localSettingsProvider.notifier)
                    .setSplashQuotesEnabled(value: value),
              ),
              if (showKeyboardShortcutAdvancedSettings(context))
                StarSettingsSwitchItem(
                  label: l10n.advancedSettingKeyboardHintsLabel,
                  description: l10n.advancedSettingKeyboardHintsDescription,
                  value: !ref.watch(
                    appearancePreferencesProvider.select(
                      (state) => state.hideKeyboardHints,
                    ),
                  ),
                  onChanged: (value) => ref
                      .read(appearancePreferencesProvider.notifier)
                      .setHideKeyboardHints(value: !value),
                ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingEnableFavoritesLabel,
                description: l10n.advancedSettingEnableFavoritesDescription,
                value: ref.watch(
                  appearancePreferencesProvider.select(
                    (state) => state.showFavorites,
                  ),
                ),
                onChanged: (value) => ref
                    .read(appearancePreferencesProvider.notifier)
                    .setShowFavorites(value: value),
              ),
              StarSettingsConfigureRow(
                title: l10n.advancedSettingVoiceChannelJoinBehaviorLabel,
                description: showKeyboardShortcutAdvancedSettings(context)
                    ? l10n.advancedSettingVoiceChannelJoinBehaviorDescription
                    : l10n.advancedSettingConfirmBeforeJoiningVoiceLabel,
                configureLabel: l10n.advancedSettingsConfigure,
                onConfigure: () => showAdvancedVoiceJoinSheet(context),
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'advanced-settings-accessibility',
            title: l10n.advancedSettingsCategoryAccessibility,
            children: [
              if (showWideLayoutAdvancedSettings(context))
                StarSettingsSwitchItem(
                  label: l10n.advancedSettingEnableTextSelectionLabel,
                  description:
                      l10n.advancedSettingEnableTextSelectionDescription,
                  value: ref.watch(
                    advancedPreferencesProvider.select(
                      (state) => state.enableTextSelection,
                    ),
                  ),
                  onChanged: (value) => ref
                      .read(advancedPreferencesProvider.notifier)
                      .setEnableTextSelection(value: value),
                ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingVideoSeekThumbnailsLabel,
                description: l10n.advancedSettingVideoSeekThumbnailsDescription,
                value: ref.watch(
                  advancedPreferencesProvider.select(
                    (state) => state.showVideoSeekPreviewThumbnails,
                  ),
                ),
                onChanged: (value) => ref
                    .read(advancedPreferencesProvider.notifier)
                    .setShowVideoSeekPreviewThumbnails(value: value),
              ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingHapticFeedbackLabel,
                description: l10n.advancedSettingHapticFeedbackDescription,
                value: ref.watch(
                  localSettingsProvider.select((state) => state.hapticsEnabled),
                ),
                onChanged: (value) => ref
                    .read(localSettingsProvider.notifier)
                    .setHapticsEnabled(value: value),
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'advanced-settings-chat',
            title: l10n.advancedSettingsCategoryChat,
            children: [
              StarSettingsSwitchItem(
                label: l10n.advancedSettingAutoSendGifsLabel,
                description: l10n.advancedSettingAutoSendGifsDescription,
                value: ref.watch(
                  chatPreferencesProvider.select(
                    (state) => state.autoSendKlipyGifs,
                  ),
                ),
                onChanged: (value) => ref
                    .read(chatPreferencesProvider.notifier)
                    .setAutoSendKlipyGifs(value: value),
              ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingSaveGifFavoritesLabel,
                description: l10n.advancedSettingSaveGifFavoritesDescription,
                value: ref.watch(
                  advancedPreferencesProvider.select(
                    (state) => state.saveGifFavoritesAsSavedMedia,
                  ),
                ),
                onChanged: (value) => ref
                    .read(advancedPreferencesProvider.notifier)
                    .setSaveGifFavoritesAsSavedMedia(value: value),
              ),
              StarSettingsConfigureRow(
                title: l10n.advancedSettingMediaButtonsLabel,
                description: l10n.advancedSettingMediaButtonsDescription,
                configureLabel: l10n.advancedSettingsConfigure,
                onConfigure: () => showAdvancedMediaButtonsSheet(context),
              ),
              StarSettingsConfigureRow(
                title: l10n.advancedSettingSearchEnginesLabel,
                description: l10n.advancedSettingSearchEnginesDescription,
                configureLabel: l10n.advancedSettingsConfigure,
                onConfigure: () => showAdvancedTextSearchEnginesSheet(context),
              ),
              StarSettingsConfigureRow(
                title: l10n.advancedSettingTranslatorsLabel,
                description: l10n.advancedSettingTranslatorsDescription,
                configureLabel: l10n.advancedSettingsConfigure,
                onConfigure: () => showAdvancedTranslatorsSheet(context),
              ),
              StarSettingsConfigureRow(
                title: l10n.advancedSettingReverseImageSearchLabel,
                description: l10n.advancedSettingReverseImageSearchDescription,
                configureLabel: l10n.advancedSettingsConfigure,
                onConfigure: () => showAdvancedReverseImageSearchSheet(context),
              ),
              if (showWideLayoutAdvancedSettings(context))
                StarSettingsConfigureRow(
                  title: l10n.advancedSettingMessageActionBarLabel,
                  description: l10n.advancedSettingMessageActionBarDescription,
                  configureLabel: l10n.advancedSettingsConfigure,
                  onConfigure: () => showAdvancedMessageActionBarSheet(context),
                ),
              StarSettingsConfigureRow(
                title: l10n.advancedSettingExpressionAutocompleteLabel,
                description:
                    l10n.advancedSettingExpressionAutocompleteDescription,
                configureLabel: l10n.advancedSettingsConfigure,
                onConfigure: () =>
                    showAdvancedExpressionAutocompleteSheet(context),
              ),
              if (showWideLayoutAdvancedSettings(context))
                StarSettingsConfigureRow(
                  title: l10n.advancedSettingInputButtonsLabel,
                  description: l10n.advancedSettingInputButtonsDescription,
                  configureLabel: l10n.advancedSettingsConfigure,
                  onConfigure: () => showAdvancedInputButtonsSheet(context),
                ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingScrollToBottomOnSendLabel,
                description:
                    l10n.advancedSettingScrollToBottomOnSendDescription,
                value: ref.watch(
                  advancedPreferencesProvider.select(
                    (state) => state.scrollToBottomOnMessageSend,
                  ),
                ),
                onChanged: (value) => ref
                    .read(advancedPreferencesProvider.notifier)
                    .setScrollToBottomOnMessageSend(value: value),
              ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingSkipMarkAllAsReadLabel,
                description: l10n.advancedSettingSkipMarkAllAsReadDescription,
                value: ref.watch(
                  advancedPreferencesProvider.select(
                    (state) => state.skipMarkAllAsReadConfirmation,
                  ),
                ),
                onChanged: (value) => ref
                    .read(advancedPreferencesProvider.notifier)
                    .setSkipMarkAllAsReadConfirmation(value: value),
              ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingHideMutedChannelsLabel,
                description: l10n.advancedSettingHideMutedChannelsDescription,
                value: ref.watch(
                  userSettingsViewModelProvider.select(
                    (state) => state.defaultHideMutedChannels,
                  ),
                ),
                onChanged: (value) => handleDefaultHideMutedChannelsChange(
                  context,
                  ref,
                  value: value,
                ),
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'advanced-settings-media',
            title: l10n.advancedSettingsCategoryMedia,
            children: [
              StarSelect<ScreenShareCodecPreference>(
                label: l10n.advancedSettingScreenShareCodecLabel,
                description: l10n.advancedSettingScreenShareCodecDescription,
                value: ref.watch(
                  voiceSettingsProvider.select(
                    (state) => state.preferredScreenShareCodec,
                  ),
                ),
                items: [
                  StarSelectItem(
                    value: ScreenShareCodecPreference.auto,
                    label: l10n.advancedSettingScreenShareCodecAuto,
                  ),
                  StarSelectItem(
                    value: ScreenShareCodecPreference.av1,
                    label: l10n.advancedSettingScreenShareCodecAv1,
                  ),
                  StarSelectItem(
                    value: ScreenShareCodecPreference.h265,
                    label: l10n.advancedSettingScreenShareCodecH265,
                  ),
                  StarSelectItem(
                    value: ScreenShareCodecPreference.vp9,
                    label: l10n.advancedSettingScreenShareCodecVp9,
                  ),
                  StarSelectItem(
                    value: ScreenShareCodecPreference.h264,
                    label: l10n.advancedSettingScreenShareCodecH264,
                  ),
                  StarSelectItem(
                    value: ScreenShareCodecPreference.vp8,
                    label: l10n.advancedSettingScreenShareCodecVp8,
                  ),
                ],
                onChanged: ref
                    .read(voiceSettingsProvider.notifier)
                    .setPreferredScreenShareCodec,
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'advanced-settings-voice',
            title: l10n.advancedSettingsCategoryVoice,
            children: [
              StarSettingsSwitchItem(
                label: l10n.advancedSettingNewDeviceAlertsLabel,
                description: l10n.advancedSettingNewDeviceAlertsDescription,
                value: !ref.watch(
                  voiceSettingsProvider.select(
                    (state) => state.suppressNewDeviceAlerts,
                  ),
                ),
                onChanged: (value) => ref
                    .read(voiceSettingsProvider.notifier)
                    .setSuppressNewDeviceAlerts(value: !value),
              ),
              StarSettingsSwitchItem(
                label: l10n.advancedSettingConnectionVolumeControlsLabel,
                description:
                    l10n.advancedSettingConnectionVolumeControlsDescription,
                value: ref.watch(
                  voiceSettingsProvider.select(
                    (state) => state.showConnectionVolumeControls,
                  ),
                ),
                onChanged: (value) => ref
                    .read(voiceSettingsProvider.notifier)
                    .setShowConnectionVolumeControls(value: value),
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'advanced-settings-developer',
            title: l10n.advancedSettingsCategoryDeveloper,
            children: [
              StarSettingsSwitchItem(
                label: l10n.advancedSettingDeveloperModeLabel,
                description: l10n.advancedSettingDeveloperModeDescription,
                value: ref.watch(
                  userSettingsViewModelProvider.select(
                    (state) => state.developerMode,
                  ),
                ),
                onChanged: (value) => ref
                    .read(userSettingsViewModelProvider.notifier)
                    .setDeveloperMode(value: value),
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'advanced-performance',
            title: l10n.advancedPerformanceReportingTitle,
            description: l10n.advancedCrashReportingSectionDescription,
            children: [
              StarSettingsSwitchItem(
                label: l10n.advancedPerformanceReportingLabel,
                description: l10n.advancedCrashReportingDescription,
                value: ref.watch(observabilityReportingProvider),
                enabled: observabilityReportingIsAvailable(
                  ref.watch(starObservabilityProvider),
                ),
                onChanged: (bool value) => ref
                    .read(observabilityReportingProvider.notifier)
                    .setEnabled(value: value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
